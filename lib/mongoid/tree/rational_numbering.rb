module Mongoid
  module Tree
    ##
    # = Mongoid::Tree::RationalNumbering
    #
    # Mongoid::Tree doesn't use rational numbers by defailt. To enable rational numbering
    # of children include both Mongoid::Tree and Mongoid::Tree::RationalNumbering into 
    # your document.
    #
    # == Utility methods
    #

    module RationalNumbering
      extend ActiveSupport::Concern

      included do
        field :rational_number_value, :type => Float
        field :rational_number_nv,    :type => Integer, :default => 0
        field :rational_number_dv,    :type => Integer, :default => 0
        field :rational_number_snv,   :type => Integer, :default => 0
        field :rational_number_sdv,   :type => Integer, :default => 0

        # TODO: Implement check for nested children! Should not nest children.
        #validate          :will_save_tree
        
        before_validation :set_rational_numbers_if_missing

        # after_validation  :update_rational_numbers
        after_rearrange   :update_rational_numbers
        after_save        :move_children
        before_destroy    :destroy_descendants
        # before_save :assign_default_position, :if => :assign_default_position?
        # before_save :reposition_former_siblings, :if => :sibling_reposition_required?
        # after_destroy :move_lower_siblings_up
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

        def update_all_rational_numbers!
          # rekey keys for each root. will do children 
          _pos = 1
          self.roots.each do |root|
            new_keys = keys_from_parent_keys_and_position({:nv => 0, :dv => 1, :snv => 1, :sdv => 0}, _pos)
            if !compare_keys(root.tree_keys(), new_keys)
              root.move_nv_dv(new_keys[:nv], new_keys[:dv], {:ignore_conflict => true})
              root.save!
              root.reload
            end
            root.rekey_children
            _pos += 1
          end
        end


        ##
        # By a given set of parent keys and postion, the keys for a child can be calculated
        #
        # @param [Hash] containing :nv, :dv, :snv and :sdv for a given parent node
        # @param [Integer] for the given position starting at position/value 1
        #
        # @return [Hash] containing :nv, :dv, :snv and :sdv for the given position

        def keys_from_parent_keys_and_position(parent_keys, position)
          { :nv => parent_keys[:nv] + (position * parent_keys[:snv]),
            :dv => parent_keys[:dv] + (position * parent_keys[:sdv]),
            :snv => parent_keys[:nv] + ((position + 1) * parent_keys[:snv]),
            :sdv => parent_keys[:dv] + ((position + 1) * parent_keys[:sdv]) }
        end

        ##
        # Compare key1 with key2 for equality
        #
        # @param [Hash] key1 with :nv, :dv, :snv and :sdv to compare (rational numbers for item)
        # @param [Hash] key2 with :nv, :dv, :snv and :sdv to compare (rational numbers for item)
        #
        # @return [Boolean] true for equal, else false
        
        def compare_keys(key1, key2)
        ( (key1[:nv] === key2[:nv]) and
          (key1[:dv] === key2[:dv]) and
          (key1[:snv] === key2[:snv]) and
          (key1[:sdv] === key2[:sdv]))
        end

        ##
        # Get the position from a given nv and dv value
        #
        # @param [Integer] nv - the nominator for the given node
        # @param [Integer] dv - the denominator for the given node
        #
        # @return [Integer] position for the given nv/dv values

        def position_from_nv_dv(nv, dv)
          anc_tree_keys = ancestor_tree_keys(nv, dv)
          (nv - anc_tree_keys[:nv]) / anc_tree_keys[:snv]
        end
        
        ##
        # Get ancestor nv, dv, snv, sdv values as hash for a given nv/dv combination
        #
        # @param [Integer] nv - the nominator for the given node
        # @param [Integer] dv - the denominator for the given node
        #
        # @return [Hash] containing :nv, :dv, :snv and :sdv for the given position

        def ancestor_tree_keys(nv,dv)
          numerator = nv
          denominator = dv
          ancnv = 0
          ancdv = 1
          ancsnv = 1
          ancsdv = 0
          rethash = {:nv => ancnv, :dv => ancdv, :snv => ancsnv, :sdv => ancsdv}
          # make sure we break if we get root values! (numerator == 0 + denominator == 0)
          #max_levels = 10
          while ((ancnv < nv) && (ancdv < dv)) && ((numerator > 0) && (denominator > 0))# && (max_levels > 0)
            #max_levels -= 1
            div = numerator / denominator
            mod = numerator % denominator
            # set return values to previous values, as they are the parent values
            rethash = {:nv => ancnv, :dv => ancdv, :snv => ancsnv, :sdv => ancsdv}

            ancnv = ancnv + (div * ancsnv)
            ancdv = ancdv + (div * ancsdv)
            ancsnv = ancnv + ancsnv
            ancsdv = ancdv + ancsdv

            numerator = mod
            if (numerator != 0)
              denominator = denominator % mod
              if denominator == 0
                denominator = 1
              end
            end
          end
          return rethash
        end #get_ancestor_keys(nv,dv)

      # THIS IS FROM THE MONGOMAPPER PLUGIN. HAS TO BE FIXED
      def initialize(*args)
        @_will_move = false
        @_rational_numbers_set = false
        super
      end

      end # Classmethods

      ## 
      # Get the keys from the next sibling (calculation)
      #
      # This is used for sdv and snv values when setting the nv/dv on a node
      # 
      # @return [Hash] containing :nv, :dv, :snv and :sdv for the next sibling

      def next_sibling_keys
        keys_from_position(self.class.position_from_nv_dv(self.rational_number_nv, self.rational_number_dv) +1)
      end

      ## 
      # Get the ancestor keys from calculation instead of query
      # Only used to to save queries and should be used with caution, as it does not
      # verify if the ancestor exists
      # 
      # @return [Hash] containing :nv, :dv, :snv and :sdv for the ancestor

      def ancestor_tree_keys
        self.class.ancestor_tree_keys(self.rational_number_nv, self.rational_number_dv)
      end

      def tree_keys
        { :nv => self.rational_number_nv, 
          :dv => self.rational_number_dv, 
          :snv => self.rational_number_snv, 
          :sdv => self.rational_number_sdv}
      end

      ## 
      # Get the ancestor keys from a query instead of calculation
      #
      # @return [Hash] containing :nv, :dv, :snv and :sdv for the ancestor

      def query_ancestor_tree_keys
        check_parent = self.where(:_id => self[:parent_ids]).first
        return nil if (check_parent.nil? || check_parent == [])
        rethash = {:nv  => check_parent.rational_number_nv, 
                   :dv  => check_parent.rational_number_dv, 
                   :snv => check_parent.rational_number_snv, 
                   :sdv => check_parent.rational_number_sdv}
      end

      ## 
      # Verify if the node has correct parent given the nv/dv combination
      # 
      # @param [Integer] nv - the nominator for the given node
      # @param [Integer] dv - the denominator for the given node
      # 
      # @return [Boolean] true for correct parent
      def correct_parent?(nv, dv)
        # get nv/dv from parent
        check_ancestor_keys = query_ancestor_tree_keys()
        return false if (check_ancestor_keys == nil)
        calc_ancestor_keys = self.class.ancestor_tree_keys(nv, dv)
        if ( (calc_ancestor_keys[:nv] == check_ancestor_keys[:nv]) \
          && (calc_ancestor_keys[:dv] == check_ancestor_keys[:dv]) \
          && (calc_ancestor_keys[:snv] == check_ancestor_keys[:snv]) \
          && (calc_ancestor_keys[:sdv] == check_ancestor_keys[:sdv]) \
          )
          return true
        end
      end

      ##
      # Set the nv and dv position
      #
      # @param [Integer] nv - the nominator for the given node
      # @param [Integer] dv - the denominator for the given node

      def set_position(nv, dv)
        self.rational_number_nv = nv
        self.rational_number_dv = dv
      end

      ## 
      # Update the rational numbers on a node
      #       
      # Should calculate next free nv/dv and se if parent has changed.
      #
      # @param [Hash] opts    - :position - the position to use when setting new keys
      #                         :force - force setting new nv/dv values

      def update_rational_numbers(opts = {})
        if @_rational_numbers_set == true
          @_rational_numbers_set = false
          return
        end
        # if changes include both parent_id, tree_info.nv and tree_info.dv, 
        # checking in validatioon that the parent is correct.
        # if change is only nv/dv, check if parent is correct, move it...
        if (self.changes.include?("rational_number_") && self.changes.include?("rational_number_dv"))
          self.move_nv_dv(self.rational_number_nv, self.rational_number_dv)
        elsif (self.changes.include?(:parent_ids)) || opts[:force]
          # only changed parent, needs to find next free position
          # use function for "missing nv/dv"
          new_keys = self.keys_from_position((self.has_siblings? + 1)) if !opts[:position]
          new_keys = self.keys_from_position((opts[:position] + 1)) if opts[:position]
          self.move_nv_dv(new_keys[:nv], new_keys[:dv])
        end
      end

      ##
      # Force update of rational numbers

      def update_rational_numbers!(opts = {})
        update_rational_numbers({:force => true}.merge(opts))
      end

      ##
      # Sets initial nv, dv, snv and sdv values and float value
      # 
      # Used on create callback

      def set_rational_numbers_if_missing
        if (self.rational_number_nv == 0 || self.rational_number_dv == 0 )
          last_sibling = self.siblings.last
          if (last_sibling == nil)
            last_sibling_position = 0
          else
            last_sibling_position = self.class.position_from_nv_dv(last_sibling.rational_number_nv, last_sibling.rational_number_dv)
          end
          new_keys = self.keys_from_position((last_sibling_position + 1) )
          self.rational_number_nv = new_keys[:nv]
          self.rational_number_dv = new_keys[:dv]
          self.rational_number_snv = new_keys[:snv]
          self.rational_number_sdv = new_keys[:sdv]
          self.rational_number_value = Float(new_keys[:nv]/Float(new_keys[:dv]))
          @_rational_numbers_set = true
        end
      end

      ##
      # Move rational position to given nv and dv
      #
      # if conflcting item on new position, shift all siblings right and insert
      # can force move without updating conflicting siblings
      #
      # @param [Integer] nv - the nominator for the given node
      # @param [Integer] dv - the denominator for the given node
      # @param [Hash] opts - :ignore_conflict - force setting new nv/dv values and ignore conflicting items
      # 
      def move_rational_position(nv, dv, opts = {})
        position = self.class.position_from_nv_dv(nv, dv)
        if !self.root?
          anc_keys = self.class.ancestor_tree_keys(nv, dv)
          rnv = anc_keys[:nv] + ((position + 1) * anc_keys[:snv])
          rdv = anc_keys[:dv] + ((position + 1) * anc_keys[:sdv])
        else
          rnv = position + 1
          rdv = 1
        end

        # don't check for conflict if forced move
        if (!opts[:ignore_conflict])
          conflicting_sibling = self.where(:rational_number_nv => nv).where(:rational_number_dv => dv).first
          if (conflicting_sibling != nil) 
            self.disable_timestamp_callback()
            # find nv/dv to the right of conflict
            # find position/count for this item
            next_keys = conflicting_sibling.next_sibling_keys
            conflicting_sibling.set_position(next_keys[:nv], next_keys[:dv])
            conflicting_sibling.save
            self.enable_timestamp_callback()
          end
        end

        # shouldn't be any conflicting sibling now...
        self.rational_number_nv    = nv
        self.rational_number_dv    = dv
        self.rational_number_snv   = rnv
        self.rational_number_sdv   = rdv
        self.rational_number_value = Float(self.rational_number_nv)/Float(self.rational_number_dv)
        # as this is triggered from after_validation, save should be triggered by the caller.
      end

      ##
      # Temporarily disable timestamp callbacks when this item shifts other items around
      #

      def disable_timestamp_callback
        if self.respond_to?("updated_at")
          @@_disable_timestamp_count += 1
          self.class.skip_callback(:save, :before, :set_updated_at ) 
        end
      end

      ##
      # Enable timestamp callbacks (must be called after disable_timestamp_callback blocks are done)
      def enable_timestamp_callback
        if self.respond_to?("updated_at")
          @@_disable_timestamp_count -= 1
          self.class.set_callback(:save, :before, :set_updated_at ) if @@_disable_timestamp_count <= 0
        end
      end

      ##
      # Get keys from given position
      #
      # @param [Integer] for the given position starting at position/value 1
      #
      # @return [Hash] containing :nv, :dv, :snv and :sdv for the given position

      def keys_from_position(position)
        # replace with self.parent?
        _parent = self.class.where(:_id => self.parent_id).first
        _parent = nil if ((_parent.nil?) || (_parent == []))
        ancnv = 0
        ancsnv = 1
        ancdv = 1
        ancsdv = 0
        if _parent != nil
          ancnv  = _parent.rational_number_nv
          ancsnv = _parent.rational_number_snv
          ancdv  = _parent.rational_number_dv
          ancsdv = _parent.rational_number_sdv
        end
        self.class.keys_from_parent_keys_and_position({:nv => ancnv, :dv => ancdv, :snv => ancsnv, :sdv => ancsdv}, position)
      end

      ##
      # Move the children to correct new position
      def move_children
        return
        if @_will_move
          @_will_move = false
          _position = 0
          self.disable_timestamp_callback()
          self.children.each do |child|
            child.update_path!
            child.update_nv_dv!(:position => _position)
            child.save
            child.reload
            _position += 1
          end
          self.enable_timestamp_callback()

          # enable_tree_callbacks()
          @_will_move = true
        end
      end


    private

    end
  end
end



# # TODO: FIX THESE TO USE NV/DV
#       ##
#       # Returns a chainable criteria for this document's ancestors
#       #
#       # @return [Mongoid::Criteria] Mongoid criteria to retrieve the document's ancestors
#       def ancestors
#         base_class.unscoped.where(:_id.in => parent_ids)
#       end

#       ##
#       # Returns siblings below the current document.
#       # Siblings with a position greater than this document's position.
#       #
#       # @return [Mongoid::Criteria] Mongoid criteria to retrieve the document's lower siblings
#       def lower_siblings
#         # self.siblings.where(:position.gt => self.position)
#       end

#       ##
#       # Returns siblings above the current document.
#       # Siblings with a position lower than this document's position.
#       #
#       # @return [Mongoid::Criteria] Mongoid criteria to retrieve the document's higher siblings
#       def higher_siblings
#         self.siblings.where(:position.lt => self.position)
#       end

#       ##
#       # Returns siblings between the current document and the other document
#       # Siblings with a position between this document's position and the other document's position.
#       #
#       # @return [Mongoid::Criteria] Mongoid criteria to retrieve the documents between this and the other document
#       def siblings_between(other)
#         range = [self.position, other.position].sort
#         self.siblings.where(:position.gt => range.first, :position.lt => range.last)
#       end

#       ##
#       # Returns the lowest sibling (could be self)
#       #
#       # @return [Mongoid::Document] The lowest sibling
#       def last_sibling_in_list
#         siblings_and_self.last
#       end

#       ##
#       # Returns the highest sibling (could be self)
#       #
#       # @return [Mongoid::Document] The highest sibling
#       def first_sibling_in_list
#         siblings_and_self.first
#       end

#       ##
#       # Is this the highest sibling?
#       #
#       # @return [Boolean] Whether the document is the highest sibling
#       def at_top?
#         higher_siblings.empty?
#       end

#       ##
#       # Is this the lowest sibling?
#       #
#       # @return [Boolean] Whether the document is the lowest sibling
#       def at_bottom?
#         lower_siblings.empty?
#       end

#       ##
#       # Move this node above all its siblings
#       #
#       # @return [undefined]
#       def move_to_top
#         return true if at_top?
#         move_above(first_sibling_in_list)
#       end

#       ##
#       # Move this node below all its siblings
#       #
#       # @return [undefined]
#       def move_to_bottom
#         return true if at_bottom?
#         move_below(last_sibling_in_list)
#       end

#       ##
#       # Move this node one position up
#       #
#       # @return [undefined]
#       def move_up
#         switch_with_sibling_at_offset(-1) unless at_top?
#       end

#       ##
#       # Move this node one position down
#       #
#       # @return [undefined]
#       def move_down
#         switch_with_sibling_at_offset(1) unless at_bottom?
#       end

#       ##
#       # Move this node above the specified node
#       #
#       # This method changes the node's parent if nescessary.
#       #
#       # @param [Mongoid::Tree] other document to move this document above
#       #
#       # @return [undefined]
#       def move_above(other)
#         ensure_to_be_sibling_of(other)

#         if position > other.position
#           new_position = other.position
#           self.siblings_between(other).inc(:position, 1)
#           other.inc(:position, 1)
#         else
#           new_position = other.position - 1
#           self.siblings_between(other).inc(:position, -1)
#         end

#         self.position = new_position
#         save!
#       end

#       ##
#       # Move this node below the specified node
#       #
#       # This method changes the node's parent if nescessary.
#       #
#       # @param [Mongoid::Tree] other document to move this document below
#       #
#       # @return [undefined]
#       def move_below(other)
#         ensure_to_be_sibling_of(other)

#         if position > other.position
#           new_position = other.position + 1
#           self.siblings_between(other).inc(:position, 1)
#         else
#           new_position = other.position
#           self.siblings_between(other).inc(:position, -1)
#           other.inc(:position, -1)
#         end

#         self.position = new_position
#         save!
#       end

# # END TODO: FIX THESE TO USE NV/DV
