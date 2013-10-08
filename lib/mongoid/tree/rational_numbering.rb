I18n.load_path << File.expand_path('../../locale/en.yml', __FILE__)

# TODO: ADD VALIDATIONS!

require 'rational_number'

module Mongoid
  module Tree
    ##
    # = Mongoid::Tree::RationalNumbering
    #
    # Mongoid::Tree doesn't use rational numbers by default. To enable rational numbering
    # of children include both Mongoid::Tree and Mongoid::Tree::RationalNumbering into
    # your document.
    #
    # == Utility methods
    #

    module RationalNumbering
      extend ActiveSupport::Concern

      @@_disable_timestamp_count = 0

      included do
        field :rational_number_nv,    :type => Integer, :default => 0
        field :rational_number_dv,    :type => Integer, :default => 1
        field :rational_number_snv,   :type => Integer, :default => 1
        field :rational_number_sdv,   :type => Integer, :default => 0
        field :rational_number_value, :type => BigDecimal

        validate          :validate_rational_hierarchy

        # after_rearrange   :assign_initial_rational_number, :if => :assign_initial_rational_number?

        # after_rearrange   :set_initial_rational_number, :if :set_initial_rational_number?

        after_rearrange   :update_rational_number, :if => :update_rational_number?

        # Rekey former siblings to avoid gaps in the rational structure
        after_save        :rekey_former_siblings, :if => :rekey_former_siblings?

        # Rekey all the children of the node if needed
        after_save        :rekey_children, :if => :rekey_children?

        ### ??? ADD SOME STRATEGY???
        # before_destroy    :destroy_descendants

        after_destroy :move_lower_siblings

        default_scope asc(:rational_number_value)

      end # included do

      module ClassMethods

        # helper metods for nv/dv

        ##
        # Force all rational number keys to update
        #
        # Can be used to remove any "gaps" that are in a tree
        #
        # For large collections, this uses a lot of resources, and should probably be used
        # in a backround job on production sites. As a rational tree works just fine even
        # if there are missing items, this shouldn't  be necessary to do that often.

        def rekey_all!
          # rekey keys for each root. will do children
          _pos = 1
          root_rational = RationalNumber.new
          self.roots.each do |root|
            new_rational = root_rational.child_from_position(_pos)
            if new_rational != root.rational_number
              root.move_to_rational_number(new_rational.nv, new_rational.dv, {:force => true})
              root.save_with_force_rational_numbers!
              # root.reload # Should caller be responsible for reloading?
            end
            root.rekey_children
            _pos += 1
          end
        end

      end # Classmethods


      ##
      # Initialize the rational tree document
      #
      # @return [undefined]
      #
      def initialize(*args)
        @_forced_rational_number = false
        @_rational_moving_nodes  = false
        super
      end

      ##
      #
      # Validate that this document has the correct parent document through a query
      # If not, the parent must be set before setting nv/dv driectly
      #
      # @return true for valid, else false
      #
      def validate_rational_hierarchy
        if self.rational_number_nv_changed? && self.rational_number_dv_changed?
          # puts "#{self.name} #{self.changes.inspect}"
          unless correct_rational_parent?(self.rational_number_nv, self.rational_number_dv)
            errors.add(:base, I18n.t(:cyclic, :scope => [:mongoid, :errors, :messages, :tree]))
          end
        end
      end


      ##
      #
      # [INTERNAL] Move the document to a given position (integer based, starting with 1)
      #
      # if a document exists on the new position, all siblings are shifted right before moving this document
      # can move without updating conflicting siblings by using :force in options
      #
      # @param [Integer] The positional value
      # @param [Hash] Options: :force (defaults to false)
      #
      # @return [undefined]
      #
      def move_to_position(_position, opts = {})
        new_rational_number = parent_rational_number.child_from_position(_position)
        move_to_rational_number(new_rational_number.nv, new_rational_number.dv, opts)
      end

      ##
      #
      # [INTERNAL] Move the document to a given rational_number position
      #
      # if a document exists on the new position, all siblings are shifted right before moving this document
      # can move without updating conflicting siblings by using :ignore_conflicts in options
      #
      # @param [Integer] The nominator value
      # @param [Integer] The denominator value
      # @param [Hash] Options: :force (defaults to false)
      #
      # @return [undefined]
      #
      def move_to_rational_number(nv, dv, opts = {})
        # don't check for conflict if forced move
        move_conflicting_nodes(nv,dv) unless !!opts[:force]

        # shouldn't be any conflicting sibling now...
        self.from_rational_number(RationalNumber.new(nv,dv))
      end

      ##
      #
      # This can be used to set a rational number directly
      # The node will be moved to the correct parent
      #
      # If the given nv/dv does not find an existing parent, it will add an validation error
      #
      # If the given nv/dv is higher than the last sibling under the parent, the nv/dv will be recalculated
      # to appropriate nv/dv values
      #
      def set_rational_number(nv,dv, do_save = true)
        # return true of already at the right spot
        # puts "#{self.name} - set_rational_number #{nv}/#{dv} self:#{self.rational_number_nv}/#{self.rational_number_dv}"
        return true if self.rational_number_nv == nv && self.rational_number_dv == dv && (!self.rational_number_nv_changed? && !self.rational_number_dv_changed?)
        # check if parent exist
        # puts "  parent exists: #{parent_exists?(nv,dv).inspect}"
        unless parent_exists?(nv,dv)
          errors.add(:base, I18n.t(:parent_does_not_exist, :scope => [:mongoid, :errors, :messages, :tree, :rational], nv: nv, dv: dv) )
          return false
        end
        # find other/conflicting sibling
        other = base_class.where(:rational_number_nv => nv).where(:rational_number_dv => dv).excludes(:id => self.id).first
        already_sibling_of = other.nil? ? false : self.sibling_of?(other)

        # puts "  conflict: #{other.nil?} already_sibling_of :#{already_sibling_of}"
        return false if ensure_to_have_correct_parent(nv,dv) == false

        move_to_rational = RationalNumber.new(nv,dv)

        unless other.nil?
          if already_sibling_of
            # puts "  already sibling of other, so moving down"
            return if other.position == self.position + 1
            # If there are nodes between this and other before move, make sure they are shifted upwards before moving
            _direction = (self.position > other.position ? 1 : -1)
            _position = (_direction < 0 ? other.position + _direction : other.position)
            shift_nodes_position(other, _direction, (_direction > 0 ? false : true))

            # There should not be conflicting nodes at this stage.
            move_to_position(_position)
          else
            # puts "  shifting lower nodes from other"
            shift_lower_nodes_from_other(other, 1)
          end
        else
          # make sure the new position is the next rational value under the parent
          # as there was no "other" to move
          new_parent = base_class.where(:id => self.parent_id).first
          if new_parent.nil?
            # count roots
            root_count = base_class.roots.count
            move_to_rational = RationalNumber.new.child_from_position(root_count+1)
            # puts "  new parent is root root_count: #{root_count} new 'correct position' is : #{move_to_rational.nv}/#{move_to_rational.dv}"
          else
            child_count = new_parent.children.count
            move_to_rational = new_parent.rational_number.child_from_position(child_count+1)
            # puts "  new parent is not root child_count: #{child_count} new 'correct position' is : #{move_to_rational.nv}/#{move_to_rational.dv}"
          end
        end
        move_to_rational_number(move_to_rational.nv, move_to_rational.dv, {:force => true})
        if do_save
          save
        else
          true
        end
      end

      ##
      #
      # Check if a parent exists for the given nv/dv values
      #
      # Will return true if the parent is "root" and the node should be created
      # as a root element
      #
      def parent_exists?(nv,dv)
        q_parent = base_class.where(:rational_number_nv => nv).where(:rational_number_dv => dv).excludes(:id => self.id).first
        if q_parent.nil?
          return true if RationalNumber.new(nv,dv).parent.root?
        else
          return true
        end
        false
      end

      ##
      #
      # Move conflicting nodes for a given value
      #
      # @param [Integer] The nominator value
      # @param [Integer] The denominator value
      #
      def move_conflicting_nodes(nv,dv)
        # As we are moving to the position of the conflicting sibling, it all items can be shifted similar to "move_above"

        conflicting_sibling = base_class.where(:rational_number_nv => nv).where(:rational_number_dv => dv).excludes(:id => self.id).first
        if (conflicting_sibling != nil)
          # ensure_to_be_sibling_of(conflicting_sibling)
          return if conflicting_sibling.position == self.position + 1
          # If there are nodes between this and conflicting_sibling before move, make sure their position shifted before moving
          _direction = (self.position > conflicting_sibling.position ? 1 : -1)
          _position = (_direction < 0 ? conflicting_sibling.position + _direction : conflicting_sibling.position)
          shift_nodes_position(conflicting_sibling, _direction, (_direction > 0 ? false : true))
        end
      end

      ##
      #
      # Query the ancestor rational number
      #
      # @return [RationalNumber] returns the rational number for the ancestor or nil for "not found"
      #
      def query_ancestor_rational_number
        check_parent = base_class.where(:_id => self.parent_id).first
        return nil if (check_parent.nil? || check_parent == [])
        check_parent.rational_number
      end

      ##
      #
      # Verifies parent keys from calculation and query
      #
      # @return [Boolean] true for correct, else false
      #
      def correct_rational_parent?(nv, dv)
        q_rational_number = query_ancestor_rational_number
        if q_rational_number.nil?
          if RationalNumber.new(nv,dv).parent.root?
            return true
          else
            return false
          end
        end
        return true if self.rational_number.parent == q_rational_number
        false
      end

      ##
      # Check if children needs to be rekeyed
      #
      def rekey_children?
        persisted? && self.children? && ( self.previous_changes.include?("rational_number_nv") || self.previous_changes.include?("parent_ids") || self.changes.include?("rational_number_nv") || self.changes.include?("parent_ids") )
      end

      ##
      #
      # Rekey each of the children (usually forcefully if a tree has gone "crazy")
      #
      # @return [undefined]
      #
      def rekey_children
        _pos = 1
        this_rational_number = self.rational_number
        self.children.each do |child|
          new_rational_number = this_rational_number.child_from_position(_pos)
          move_node_and_save_if_changed(child, new_rational_number)
          _pos += 1
        end
      end

      def rekey_former_siblings?
        persisted? && self.previous_changes.include?("parent_id")
      end

      def rekey_former_siblings
        former_siblings = base_class.where(:parent_id => attribute_was('parent_id')).
                                     and(:rational_number_value.gt => (attribute_was('rational_number_value') || 0)).
                                     excludes(:id => self.id)
        former_siblings.each do |prev_sibling|
          new_rational_number = prev_sibling.parent_rational_number.child_from_position(prev_sibling.position - 1)
          move_node_and_save_if_changed(prev_sibling, new_rational_number)
        end
      end

      def move_node_and_save_if_changed(node, new_rational_number)
        if new_rational_number != node.rational_number
          node.move_to_rational_number(new_rational_number.nv, new_rational_number.dv, {:force => true})
          node.save_with_force_rational_numbers!
          # node.reload # Should caller be responsible for reloading?
        end
      end

      ##
      #
      # Not needed, as each child gets the rational number updated after updating path?
      # @return [undefined]
      #
      # def children_update_rational_number
      #   if rearrange_children?
      #     _position = 0
      #     # self.disable_timestamp_callback()
      #     self.children.each do |child|
      #       child.update_rational_number!(:position => _position)
      #       _position += 1
      #     end
      #     # self.enable_timestamp_callback()
      #   end
      # end

      ##
      # Enable timestamping callback if existing
      #
      def enable_timestamp_callback

      end

      ##
      # Disable timestamping callback if existing
      #
      def disable_timestamp_callback

      end

      ##
      # Convert to rational number
      #
      # @return [RationalNumber] The rational number for this node
      #
      def rational_number
        RationalNumber.new(self.rational_number_nv, self.rational_number_dv, self.rational_number_snv, self.rational_number_sdv)
      end

      ##
      # Convert from rational number and set keys accordingly
      #
      # @param  [RationalNumber] The rational number for this node
      # @return [undefined]
      #
      def from_rational_number(rational_number)
        self.rational_number_nv    = rational_number.nv
        self.rational_number_dv    = rational_number.dv
        self.rational_number_snv   = rational_number.snv
        self.rational_number_sdv   = rational_number.sdv
        self.rational_number_value = rational_number.number
      end

      ##
      # Returns a chainable criteria for this document's ancestors
      #
      # @return [Mongoid::Criteria] Mongoid criteria to retrieve the document's ancestors
      def ancestors
        base_class.unscoped { super }
      end

      ##
      #
      # Returns the positional value for the current node
      #
      def position
        self.rational_number.position
      end

      ##
      # Returns siblings below the current document.
      # Siblings with a position greater than this document's position.
      #
      # @return [Mongoid::Criteria] Mongoid criteria to retrieve the document's lower siblings
      def lower_siblings
        self.siblings.where(:rational_number_value.gt => self.rational_number_value)
      end

      ##
      # Returns siblings above the current document.
      # Siblings with a position lower than this document's position.
      #
      # @return [Mongoid::Criteria] Mongoid criteria to retrieve the document's higher siblings
      def higher_siblings
        self.siblings.where(:rational_number_value.lt => self.rational_number_value)
      end

      ##
      # Returns siblings between the current document and the other document
      # Siblings with a position between this document's position and the other document's position.
      #
      # @return [Mongoid::Criteria] Mongoid criteria to retrieve the documents between this and the other document
      def siblings_between(other)
        range = [self.rational_number_value, other.rational_number_value].sort
        self.siblings.where(:rational_number_value.gt => range.first, :rational_number_value.lt => range.last)
      end

      ##
      # Return the siblings between this and other + other
      #
      def siblings_between_including_other(other)
        range = [self.rational_number_value, other.rational_number_value].sort
        self.siblings.where(:rational_number_value.gte => range.first, :rational_number_value.lte => range.last)
      end

      ##
      # Returns the lowest sibling (could be self)
      #
      # @return [Mongoid::Document] The lowest sibling
      def last_sibling_in_list
        siblings_and_self.last
      end

      ##
      # Returns the highest sibling (could be self)
      #
      # @return [Mongoid::Document] The highest sibling
      def first_sibling_in_list
        siblings_and_self.first
      end

      ##
      # Is this the highest sibling?
      #
      # @return [Boolean] Whether the document is the highest sibling
      def at_top?
        higher_siblings.empty?
      end

      ##
      # Is this the lowest sibling?
      #
      # @return [Boolean] Whether the document is the lowest sibling
      def at_bottom?
        lower_siblings.empty?
      end

      ##
      # Move this node above all its siblings
      #
      # @return [undefined]
      def move_to_top
        return true if at_top?
        move_above(first_sibling_in_list)
      end

      ##
      # Move this node below all its siblings
      #
      # @return [undefined]
      def move_to_bottom
        return true if at_bottom?
        move_below(last_sibling_in_list)
      end

      ##
      # Move this node one position up
      #
      # @return [undefined]
      def move_up
        unless at_top?
          prev_sibling = higher_siblings.last
          switch_with_sibling(prev_sibling) unless prev_sibling.nil?
        end
      end

      ##
      # Move this node one position down
      #
      # @return [undefined]
      def move_down
        unless at_bottom?
          next_sibling = lower_siblings.first
          switch_with_sibling(next_sibling) unless next_sibling.nil?
        end
      end

      ##
      # Shift nodes between self and other (or including other) in one or the other direction
      #
      # @param [Mongoid::Tree] other document to move this document above
      # @param [Integer] +1 / -1 for the direction to shift nodes
      # @param [Boolean] exclude the other object in the shift or not.
      #
      #
      def shift_nodes_position(other, direction, exclude_other = false)
        # puts "#{self.name} shift_nodes_position other: #{other.name} direction #{direction} exclude_other: #{exclude_other}"
        if exclude_other
          nodes_to_shift = siblings_between(other)
        else
          nodes_to_shift = siblings_between_including_other(other)
        end
        shift_nodes(nodes_to_shift, direction)
      end

      def shift_lower_nodes_from_other(other, direction)
        # puts "#{self.name} shift_lower_nodes_from_other other: #{other.name} direction: #{direction}"
        range = [other.rational_number_value, other.siblings.last.rational_number_value].sort
        nodes_to_shift = other.siblings_and_self.where(:rational_number_value.gte => range.first, :rational_number_value.lte => range.last)
        shift_nodes(nodes_to_shift, direction)
      end

      def shift_nodes(nodes_to_shift, direction)
        # puts "#{self.name} shift_nodes direction: #{direction}"
        nodes_to_shift.each do |node_to_shift|
          pos = node_to_shift.position + direction
          # puts "  shifting #{node_to_shift.name} from position #{node_to_shift.position} to #{pos}"
          node_to_shift.move_to_position(pos, {:force => true})
          node_to_shift.save_with_force_rational_numbers!
        end
      end

      ##
      # Move this node above the specified node
      #
      # This method changes the node's parent if nescessary.
      #
      # @param [Mongoid::Tree] other document to move this document above
      #
      # @return [undefined]
      def move_above(other)
        ensure_to_be_sibling_of(other)
        return if other.position == self.position + 1
        @_rational_moving_nodes = true
        # If there are nodes between this and other before move, make sure they are shifted upwards before moving
        _direction = (self.position > other.position ? 1 : -1)
        _position = (_direction < 0 ? other.position + _direction : other.position)
        shift_nodes_position(other, _direction, (_direction > 0 ? false : true))

        # There should not be conflicting nodes at this stage.
        move_to_position(_position)
        save!
        @_rational_moving_nodes = false
      end

      ##
      # Move this node below the specified node
      #
      # This method changes the node's parent if nescessary.
      #
      # @param [Mongoid::Tree] other document to move this document below
      #
      # @return [undefined]
      def move_below(other)
        ensure_to_be_sibling_of(other)
        return if other.position + 1 == self.position

        @_rational_moving_nodes = true

        _direction = (self.position > other.position ? 1 : -1)
        _position = (_direction > 0 ? other.position + _direction : other.position)
        shift_nodes_position(other, _direction, (_direction > 0 ? true : false))

        move_to_position(_position)
        save!
        @_rational_moving_nodes = false
      end

      ##
      # Disable the timestamps for the document type, and increase the disable count
      # Will only disable once, even if called multiple times
      #
      # @return [undefined]
      def disable_timestamp_callback
        if self.respond_to?("updated_at")
          self.class.skip_callback(:save, :before, :update_timestamps ) if @@_disable_timestamp_count == 0
          @@_disable_timestamp_count += 1
        end
      end

      ##
      # Enable the timestamps for the document type, and decrease the disable count
      # Will only enable once, even if called multiple times
      #
      # @return [undefined]
      def enable_timestamp_callback
        if self.respond_to?("updated_at")
          @@_disable_timestamp_count -= 1
          self.class.set_callback(:save, :before, :update_timestamps ) if @@_disable_timestamp_count == 0
        end
      end


      ##
      #
      # Update the rational numbers on the document if changes to parent
      # or rational number has been changed
      #
      # Should calculate next free nv/dv and set that if parent has changed.
      # (set values to "missing and call missing function should work")
      #
      # If there are both changes to nv/dv and parent_id, nv/dv settings takes
      # precedence over parent_id changes
      #
      # @return [undefined]
      #
      def update_rational_number
        if self.rational_number_nv_changed? && self.rational_number_dv_changed? && !self.rational_number_value.nil? && !set_initial_rational_number?
          self.set_rational_number(self.rational_number_nv, self.rational_number_dv, false)
        elsif self.parent_id_changed? || set_initial_rational_number?
          # only changed parent, needs to find next free position
          # Get rational number from new parent

          last_sibling = self.siblings.last

          if (last_sibling.nil?)
            new_rational_number = parent_rational_number.child_from_position(1)
          else
            new_rational_number = parent_rational_number.child_from_position(last_sibling.rational_number.position + 1)
          end

          self.move_to_rational_number(new_rational_number.nv, new_rational_number.dv)
        end
      end

      ##
      # Get the parent rational number or "root" rational number if no parent
      #
      def parent_rational_number
        if root?
          RationalNumber.new
        else
          self.parent.rational_number
        end
      end

      ##
      #
      # Check if the rational number should be updated
      #
      # @return true if it should be updated, else false
      #
      def update_rational_number?
        (set_initial_rational_number? || self.parent_id_changed? || (self.rational_number_nv_changed? && self.rational_number_dv_changed?)) && !self.forced_rational_number? && !self.moving_nodes?
      end

      ##
      # Should the initial rational number value
      #
      def set_initial_rational_number?
        self.rational_number_value.nil?
      end

      ##
      # Was the changed forced?
      #
      def forced_rational_number?
        !!@_forced_rational_number
      end

      ##
      # Currently moving nodes around?
      #
      def moving_nodes?
        !!@_rational_moving_nodes
      end

      ##
      # save when forcing rational numbers
      #
      def save_with_force_rational_numbers!
        @_forced_rational_number = true
        self.save!
        @_forced_rational_number = false
      end

      ##
      # Get the tree under the given node
      #
      def tree
        low_rational_number  = self.rational_number_value
        high_rational_number = self.rational_number.parent.child_from_position(self.position+1).number

        base_class.where(:rational_number_value.gt => low_rational_number, :rational_number_value.lt => high_rational_number)
      end

      ##
      # Get the tree under the given node
      #
      def tree_and_self
        low_rational_number  = self.rational_number_value
        high_rational_number = self.rational_number.parent.child_from_position(self.position+1).number

        base_class.where(:rational_number_value.gte => low_rational_number, :rational_number_value.lt => high_rational_number)
      end

    private

      ##
      #
      # Switch location with a given sibling
      #
      # @param [Mongoid::Tree] other document to switch places with
      #
      # @return [undefined]
      #
      def switch_with_sibling(sibling)
        self_pos = self.position
        sibling_pos = sibling.position
        sibling.move_to_position(self_pos, {:force => true})
        self.move_to_position(sibling_pos, {:force => true})
        sibling.save_with_force_rational_numbers!
        self.save_with_force_rational_numbers!
      end

      ##
      #
      # Ensure this is a sibling of given other, if not, move it to the same parent
      #
      # @param [Mongoid::Tree] other document to ensure sibling relation
      #
      # @return [undefined]
      #
      def ensure_to_be_sibling_of(other)
        return if sibling_of?(other)
        self.parent = other.parent
        save!
      end

      def ensure_to_have_correct_parent(nv,dv)
        # puts "#{self.name} ensure_to_have_correct_parent #{nv}/#{dv}"
        new_rational_number = RationalNumber.new(nv,dv)
        new_parent = nil
        # puts "  root: #{new_rational_number.root?} #{("parent: " + self.parent.name + " nv/dv : "+ self.parent.rational_number.nv.to_s+ "/"+ self.parent.rational_number.dv.to_s) unless self.parent.nil?}#{"parent: nil" if self.parent.nil?}"
        if self.parent == nil
          return true if new_rational_number.parent == RationalNumber.new
        elsif new_rational_number.parent.root?
          new_parent = nil
        else
          return true if self.parent.rational_number == new_rational_number.parent
          new_parent = base_class.where(:rational_number_nv => new_rational_number.parent.nv, :rational_number_dv => new_rational_number.dv)
          return false if new_parent.nil? # INVALID PARENT
        end
        # If entered here, the parent needs to change
        # puts "  changing parent to #{new_parent.name if !new_parent.nil?} #{"nil" if new_parent.nil?}"
        self.parent = new_parent
      end

      # FIX THESE SHIT CASE FUCK!

      def move_lower_siblings
        lower_siblings.each do |sibling|
          disable_timestamp_callback
          sibling.move_to_position(sibling.position - 1)
          sibling.save_with_force_rational_numbers!
          enable_timestamp_callback
        end
      end

      # def reposition_former_siblings
      #   former_siblings = base_class.where(:parent_id => attribute_was('parent_id')).
      #                                and(:position.gt => (attribute_was('position') || 0)).
      #                                excludes(:id => self.id)
      #   former_siblings.inc(:position,  -1)
      # end

      # def sibling_reposition_required?
      #   parent_id_changed? && persisted?
      # end



    end # RationalNumbering
  end # Tree
end # Mongoid

##
# The rational number is root and therefore has no siblings
#
class InvalidParentError < StandardError
end

