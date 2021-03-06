require 'spec_helper'
require 'timecop'

describe Mongoid::Tree::RationalNumbering do

  subject { RationalNumberedNode }

  it "should verify type of initial rational numbers" do
    f_nv  = RationalNumberedNode.fields['rational_number_nv']
    f_dv  = RationalNumberedNode.fields['rational_number_dv']
    f_snv = RationalNumberedNode.fields['rational_number_snv']
    f_sdv = RationalNumberedNode.fields['rational_number_sdv']
    f_value = RationalNumberedNode.fields['rational_number_value']
    expect(f_nv).not_to be_nil
    expect(f_nv.options[:type]).to eq(Integer)
    expect(f_dv).not_to be_nil
    expect(f_dv.options[:type]).to eq(Integer)
    expect(f_snv).not_to be_nil
    expect(f_snv.options[:type]).to eq(Integer)
    expect(f_sdv).not_to be_nil
    expect(f_sdv.options[:type]).to eq(Integer)
    expect(f_value).not_to be_nil
    expect(f_value.options[:type]).to eq(BigDecimal)
  end

  it 'should have same numbers as in the paper for rational number in nested sets theory' do
    setup_tree <<-ENDTREE
      - node_1
      - node_2:
        - node_2_1
        - node_2_2
        - node_2_3
        - node_2_4:
          - node_2_4_1
          - node_2_4_2
          - node_2_4_3
    ENDTREE

    expect(node(:node_1).rational_number).to      eq(RationalNumber.new(1,1))
    expect(node(:node_2).rational_number).to      eq(RationalNumber.new(2,1))
    expect(node(:node_2_1).rational_number).to    eq(RationalNumber.new(5,2))
    expect(node(:node_2_2).rational_number).to    eq(RationalNumber.new(8,3))
    expect(node(:node_2_3).rational_number).to    eq(RationalNumber.new(11,4))
    expect(node(:node_2_4).rational_number).to    eq(RationalNumber.new(14,5))
    expect(node(:node_2_4_1).rational_number).to  eq(RationalNumber.new(31,11))
    expect(node(:node_2_4_2).rational_number).to  eq(RationalNumber.new(48,17))
    expect(node(:node_2_4_3).rational_number).to  eq(RationalNumber.new(65,23))
  end

  describe "for roots" do
    it "should create a root node with initial rational numbers" do
      a = RationalNumberedNode.create(:name => "a")
      expect(a.rational_number).to    eq(RationalNumber.new(1,1,2,1))
    end

    it "should create two root nodes with initial rational numbers" do
      a = RationalNumberedNode.create(:name => "a")
      expect(a.rational_number).to    eq(RationalNumber.new(1,1,2,1))
      b = RationalNumberedNode.create(:name => "b")
      expect(b.rational_number).to    eq(RationalNumber.new(2,1,3,1))
    end
  end


  describe "when setting parent/children" do

    it "should set the parent of a node after creating the object" do
      a = RationalNumberedNode.create(:name => "a")
      b = RationalNumberedNode.create(:name => "b")
      b.parent = a
      b.save!
      expect(a.rational_number).to    eq(RationalNumber.new(1,1,2,1))
      expect(b.rational_number).to    eq(RationalNumber.new(3,2,5,3))
    end

    # TODO
    # it "should set the parent when creating the object" do
    # end

    it "should add children to an existing node" do
      a = RationalNumberedNode.create(:name => "a")
      b = RationalNumberedNode.create(:name => "b")
      a.children << b
      expect(a.rational_number).to    eq(RationalNumber.new(1,1,2,1))
      expect(b.rational_number).to    eq(RationalNumber.new(3,2,5,3))
    end
  end

  describe 'when saved' do
    before(:each) do

      setup_tree <<-ENDTREE
        - node_1:
          - node_1_1:
            - node_1_1_1:
              - node_1_1_1_1
          - node_1_2
          - node_1_3
        - node_2:
          - node_2_1
          - node_2_2
      ENDTREE
    end

    it "should assign a rational number to each node" do
      expect(node(:node_1).rational_number).to    eq(RationalNumber.new(1,1,2,1))
      expect(node(:node_2).rational_number).to    eq(RationalNumber.new(2,1,3,1))
      expect(node(:node_1_1).rational_number).to  eq(RationalNumber.new(3,2,5,3))
      expect(node(:node_1_2).rational_number).to  eq(RationalNumber.new(5,3,7,4))
      expect(node(:node_2_1).rational_number).to  eq(RationalNumber.new(5,2,8,3))
      expect(node(:node_2_2).rational_number).to  eq(RationalNumber.new(8,3,11,4))
    end

    it "should get the position for each of the nodes" do
      expect(node(:node_1).position).to eq(1)
      expect(node(:node_1_1).position).to eq(1)
      expect(node(:node_1_2).position).to eq(2)
    end

    it "should move a node to the end of a list when it is moved to a new parent" do
      original_root = node(:node_1)
      other_root    = node(:node_2)
      child         = node(:node_1_2)
      expect(child.position).to eq(2)
      child.parent = other_root
      child.save
      child.reload
      expect(child.position).to eq(3)
    end

    it "should correctly reposition siblings when one of them is removed" do
      rational_node_1_1 = node(:node_1_1).rational_number
      node(:node_1_1).destroy
      expect(node(:node_1_2).position).to eq(1)
      expect(node(:node_1_2).rational_number).to eq(RationalNumber.new(3,2,5,3))
    end

    it "should correctly reposition siblings when one of them is added as a child of another parent" do
      node(:node_2).children << node(:node_1_1)
      expect(node(:node_1_2).position).to eq(1)
      expect(node(:node_1_2).rational_number).to eq(RationalNumber.new(3,2,5,3))
    end

    it "should correctly reposition siblings when the parent is changed" do
      n = node(:node_1_1)
      n.parent = node(:node_2)
      n.save!
      expect(node(:node_1_2).position).to eq(1)
      expect(node(:node_1_2).rational_number).to eq(RationalNumber.new(3,2,5,3))
    end

    it "should not reposition siblings when it's not needed" do
      new_node = RationalNumberedNode.new(:name => 'new')
      new_node.parent = node(:node_1)
      expect(new_node).not_to receive(:rekey_former_siblings)
      new_node.save!
    end

  end

  describe 'destroy strategies' do
    # before(:each) do
    #   setup_tree <<-ENDTREE
    #     - root:
    #       - child:
    #         - subchild
    #       - other_child
    #     - other_root
    #   ENDTREE
    # end

    # describe ':move_children_to_parent' do
    #   it "should set its childen's parent_id to the documents parent_id" do
    #     node(:child).move_children_to_parent
    #     node(:child).should be_leaf
    #     node(:root).children.to_a.should == [node(:child), node(:other_child), node(:subchild)]
    #   end
    # end
  end

  describe 'utility methods' do
    before(:each) do
      setup_tree <<-ENDTREE
        - node_1:
          - node_1_1:
            - node_1_1_1:
              - node_1_1_1_1
          - node_1_2
          - node_1_3
        - node_2:
          - node_2_1
          - node_2_2
        - node_3
      ENDTREE
    end

    describe '#lower_siblings' do
      it "should return a collection of siblings lower on the list" do
        expect(node(:node_1).lower_siblings.to_a).to        eq([node(:node_2), node(:node_3)])
        expect(node(:node_2).lower_siblings.to_a).to        eq([node(:node_3)])
        expect(node(:node_3).lower_siblings.to_a).to        eq([])
        expect(node(:node_1_1).lower_siblings.to_a).to      eq([node(:node_1_2), node(:node_1_3)])
        expect(node(:node_2_2).lower_siblings.to_a).to      eq([])
        expect(node(:node_1_1_1).lower_siblings.to_a).to    eq([])
        expect(node(:node_1_1_1_1).lower_siblings.to_a).to  eq([])
      end
    end

    describe '#higher_siblings' do
      it "should return a collection of siblings lower on the list" do
        expect(node(:node_1).higher_siblings.to_a).to   eq([])
        expect(node(:node_2).higher_siblings.to_a).to   eq([node(:node_1)])
        expect(node(:node_3).higher_siblings.to_a).to   eq([node(:node_1), node(:node_2)])
        expect(node(:node_1_1).higher_siblings.to_a).to eq([])
        expect(node(:node_1_2).higher_siblings.to_a).to eq([node(:node_1_1)])
      end
    end

    describe '#at_top?' do
      it "should return true when the node is first in the list" do
        expect(node(:node_1)).to    be_at_top
        expect(node(:node_1_1)).to  be_at_top
      end

      it "should return false when the node is not first in the list" do
        expect(node(:node_2)).not_to   be_at_top
        expect(node(:node_3)).not_to   be_at_top
        expect(node(:node_1_2)).not_to be_at_top
      end
    end

    describe '#at_bottom?' do
      it "should return true when the node is last in the list" do
        expect(node(:node_3)).to   be_at_bottom
        expect(node(:node_1_3)).to be_at_bottom
      end

      it "should return false when the node is not last in the list" do
        expect(node(:node_1)).not_to   be_at_bottom
        expect(node(:node_2)).not_to   be_at_bottom
        expect(node(:node_1_1)).not_to be_at_bottom
      end
    end

    describe '#last_sibling_in_list' do
      it "should return the last sibling in the list containing the current sibling" do
        expect(node(:node_1).last_sibling_in_list).to eq(node(:node_3))
        expect(node(:node_2).last_sibling_in_list).to eq(node(:node_3))
        expect(node(:node_3).last_sibling_in_list).to eq(node(:node_3))
      end
    end

    describe '#first_sibling_in_list' do
      it "should return the first sibling in the list containing the current sibling" do
        expect(node(:node_1).first_sibling_in_list).to eq(node(:node_1))
        expect(node(:node_2).first_sibling_in_list).to eq(node(:node_1))
        expect(node(:node_3).first_sibling_in_list).to eq(node(:node_1))
      end
    end

    describe '#ancestors' do
      it "should be returned in the correct order" do
        setup_tree <<-ENDTREE
          - root:
            - level_1_a
            - level_1_b:
              - level_2_a:
                - leaf
        ENDTREE

        expect(node(:leaf).ancestors.to_a).to eq([node(:root), node(:level_1_b), node(:level_2_a)])
      end

      it "should return the ancestors in correct order after rearranging" do
        setup_tree <<-ENDTREE
          - node_1:
            - node_1_1:
              - node_1_1_1
        ENDTREE

        node_1_1 = node(:node_1_1)
        node_1_1.parent = nil
        node_1_1.save!

        node_1 = node(:node_1)
        node_1.parent = node(:node_1_1)
        node_1.save!

        node_1_1_1 = node(:node_1_1_1)
        node_1_1_1.parent = node_1
        node_1_1_1.save!

        expect(node_1_1_1.ancestors.to_a).to eq([node_1_1, node_1])
      end
    end
  end

  describe 'moving nodes with large tree' do
    before(:each) do

  #     setup_tree <<-ENDTREE
  #       - node_1:
  #         - node_1_1:
  #           - node_1_1_1:
  #             - node_1_1_1_1
  #         - node_1_2
  #         - node_1_3
  #       - node_2:
  #         - node_2_1
  #         - node_2_2
  #       - node_3
  #     ENDTREE

      setup_tree <<-ENDTREE
        - node_1:
          - node_1_1
          - node_1_2:
            - node_1_2_1:
              - node_1_2_1_1
              - node_1_2_1_2
            - node_1_2_2:
              - node_1_2_2_1
              - node_1_2_2_2
              - node_1_2_2_3
        - node_2:
          - node_2_1
          - node_2_2
          - node_2_3
          - node_2_4:
            - node_2_4_1
            - node_2_4_2
            - node_2_4_3
        - node_3:
          - node_3_1
          - node_3_2
          - node_3_3
      ENDTREE
    end

    describe '#move_below' do

      it 'should verify rational numbers after moving' do
        expect(node(:node_1).position).to eq(1)
        expect(node(:node_2).position).to eq(2)
        expect(node(:node_3).position).to eq(3)
        node_to_move = node(:node_1)
        node_to_move.move_below(node(:node_2))
        expect(node(:node_1).position).to eq(2)
        expect(node(:node_2).position).to eq(1)
        expect(node(:node_3).position).to eq(3)
        expect(node(:node_1).rational_number).to eq(RationalNumber.new(2,1))
        expect(node(:node_2).rational_number).to eq(RationalNumber.new(1,1))
        expect(node(:node_3).rational_number).to eq(RationalNumber.new(3,1))
      end

      it 'should fix positions within the current list when moving an sibling away from its current parent' do
        node_to_move = node(:node_1_1)
        node_to_move.move_below(node(:node_2_1))
        expect(node(:node_1_2).position).to eq(1)
        expect(node(:node_1_2).rational_number).to eq(RationalNumber.new(3,2))
      end

      it 'should work when moving to a different parent' do
        node_to_move = node(:node_1_1)
        new_parent = node(:node_2)
        node_to_move.move_below(node(:node_2_1))
        node_to_move.reload
        expect(node_to_move.position).to eq(2)
        # expect(node_to_move.rational_number).to eq(RationalNumber.new(14,5))
        # expect(node(:node_2_1).rational_number).to eq(RationalNumber.new(17,6))
        expect(node(:node_1_2)).to be_at_top
        expect(node(:node_2_1)).to be_at_top
      end

      it 'should be able to move the first node below the second node' do
        first_node = node(:node_1)
        second_node = node(:node_2)
        first_node.move_below(second_node)
        first_node.reload
        second_node.reload
        expect(second_node).to be_at_top
        expect(first_node.higher_siblings.to_a).to eq([second_node])
      end

      it 'should be able to move the last node below the first node' do
        first_node = node(:node_1)
        last_node = node(:node_3)
        last_node.move_below(first_node)
        first_node.reload
        last_node.reload
        expect(last_node).not_to be_at_bottom
        expect(node(:node_2)).to be_at_bottom
        expect(last_node.higher_siblings.to_a).to eq([first_node])
      end

      it 'should rekey the children of a node when moving to a new parent' do
        node_1_2_1_prev_keys   = node(:node_1_2_1).rational_number
        node_1_2_1_2_prev_keys = node(:node_1_2_1_2).rational_number
        node_2_4_1_prev_keys   = node(:node_2_4_1).rational_number
        node_2_4_2_prev_keys   = node(:node_2_4_2).rational_number
        node_1_2 = node(:node_1_2)
        node_1_2.move_below(node(:node_2_3))

        expect(node(:node_1_2_1).rational_number).not_to   eq(node_1_2_1_prev_keys)
        expect(node(:node_1_2_1_2).rational_number).not_to eq(node_1_2_1_2_prev_keys)

        # As these takes "over" the positions for former nodes, check equality of previous positions
        expect(node(:node_1_2_1).rational_number).to       eq(node_2_4_1_prev_keys)
        expect(node(:node_1_2_2).rational_number).to       eq(node_2_4_2_prev_keys)
        expect(node(:node_1_2_1_2).rational_number).to     eq(RationalNumber.new(127,45))
      end
    end

    describe '#move_above' do
      it 'should verify rational numbers after moving' do
        expect(node(:node_1).position).to eq(1)
        expect(node(:node_2).position).to eq(2)
        expect(node(:node_3).position).to eq(3)
        node_to_move = node(:node_1)
        node_to_move.move_above(node(:node_3))
        expect(node(:node_1).position).to eq(2)
        expect(node(:node_2).position).to eq(1)
        expect(node(:node_3).position).to eq(3)
        expect(node(:node_1).rational_number).to eq(RationalNumber.new(2,1))
        expect(node(:node_2).rational_number).to eq(RationalNumber.new(1,1))
        expect(node(:node_3).rational_number).to eq(RationalNumber.new(3,1))
      end

      it 'should fix positions within the current list when moving an sibling away from its current parent' do
        node_to_move = node(:node_1_1)
        node_to_move.move_above(node(:node_2_1))
        expect(node(:node_1_2).position).to eq(1)
        expect(node(:node_1_1).position).to eq(1)
        expect(node(:node_2_1).position).to eq(2)
      end

      it 'should work when moving to a different parent' do
        # store children rational numbers before move
        node_to_move = node(:node_1_1)
        node_to_move.move_above(node(:node_2_4))
        node_to_move.reload
        expect(node_to_move.position).to eq(4)
        expect(node_to_move.rational_number).to eq(RationalNumber.new(14,5))
        expect(node(:node_2_4).rational_number).to eq(RationalNumber.new(17,6))
        expect(node(:node_2_4)).to be_at_bottom
      end

      it 'should move children when a node is moved due to insert of another node above' do
        # store children rational numbers before move
        expect(node(:node_2_4_1).rational_number).to eq(RationalNumber.new(31,11))
        expect(node(:node_2_4_2).rational_number).to eq(RationalNumber.new(48,17))
        expect(node(:node_2_4_3).rational_number).to eq(RationalNumber.new(65,23))
        prev_2_4_1 = node(:node_2_4_1).rational_number
        prev_2_4_2 = node(:node_2_4_2).rational_number
        prev_2_4_3 = node(:node_2_4_3).rational_number
        node_to_move = node(:node_1_1)
        node_to_move.move_above(node(:node_2_4))
        node_to_move.reload

        # verify that children of 2.4 is moved to new position
        expect(node(:node_2_4_1).rational_number).not_to eq(prev_2_4_1)
        expect(node(:node_2_4_2).rational_number).not_to eq(prev_2_4_2)
        expect(node(:node_2_4_3).rational_number).not_to eq(prev_2_4_3)

        expect(node(:node_2_4_1).rational_number).to eq(RationalNumber.new(37,13))
        expect(node(:node_2_4_2).rational_number).to eq(RationalNumber.new(57,20))
        expect(node(:node_2_4_3).rational_number).to eq(RationalNumber.new(77,27))
      end

      it 'should be able to move the last node above the second node' do
        last_node = node(:node_3)
        second_node = node(:node_2)
        last_node.move_above(second_node)
        last_node.reload
        second_node.reload
        expect(second_node).to be_at_bottom
        expect(last_node.higher_siblings.to_a).to eq([node(:node_1)])
      end

      it 'should be able to move the first node above the last node' do
        first_node = node(:node_1)
        last_node = node(:node_3)
        first_node.move_above(last_node)
        first_node.reload
        last_node.reload
        expect(node(:node_2)).to be_at_top
        expect(first_node.higher_siblings.to_a).to eq([node(:node_2)])
      end

      it 'should rekey the children of a node when moving to a new parent' do
        node_1_2_1_prev_keys   = node(:node_1_2_1).rational_number
        node_1_2_1_2_prev_keys = node(:node_1_2_1_2).rational_number
        node_2_4_1_prev_keys   = node(:node_2_4_1).rational_number
        node_2_4_2_prev_keys   = node(:node_2_4_2).rational_number
        node_1_2 = node(:node_1_2)
        node_1_2.move_above(node(:node_2_4))

        expect(node(:node_1_2_1).rational_number).not_to   eq(node_1_2_1_prev_keys)
        expect(node(:node_1_2_1_2).rational_number).not_to eq(node_1_2_1_2_prev_keys)

        # As these takes "over" the positions for former nodes, check equality of previous positions
        expect(node(:node_1_2_1).rational_number).to       eq(node_2_4_1_prev_keys)
        expect(node(:node_1_2_2).rational_number).to       eq(node_2_4_2_prev_keys)
        expect(node(:node_1_2_1_2).rational_number).to     eq(RationalNumber.new(127,45))
      end
    end
  end # moving nodes with large tree

  describe 'moving nodes with small tree' do
    before(:each) do

      setup_tree <<-ENDTREE
        - node_1:
          - node_1_1
          - node_1_2
        - node_2:
          - node_2_1
          - node_2_2
          - node_2_3
          - node_2_4:
            - node_2_4_1
            - node_2_4_2
            - node_2_4_3
        - node_3
      ENDTREE
    end

    # THIS IS NOT IMPLEMENTED, as it should NOT be used this way
    describe "setting position or nv/dv values directly" do
      it "should move conflicting nodes and their children when using attribs to set nv/dv (first test)" do
        node_2_1 = node(:node_2_1)
        node_2_1.rational_number_nv = 2
        node_2_1.rational_number_dv = 1
        node_2_1.save!
        expect(node(:node_1).rational_number).to eq(RationalNumber.new(1,1))
        expect(node(:node_2_1).rational_number).to eq(RationalNumber.new(2,1))
        expect(node(:node_2).rational_number).to eq(RationalNumber.new(3,1))
        expect(node(:node_2_2).rational_number).to eq(RationalNumber.new(7,2))
        expect(node(:node_3).rational_number).to eq(RationalNumber.new(4,1))
      end

      it "should move conflicting nodes and their children when using attribs to set nv/dv (second test)" do
        node_2_1 = node(:node_2_1)
        node_2_1.rational_number_nv = 1
        node_2_1.rational_number_dv = 1
        node_2_1.save!
        expect(node(:node_2_1).rational_number).to eq(RationalNumber.new(1,1))
        expect(node(:node_1).rational_number).to eq(RationalNumber.new(2,1))
        expect(node(:node_2).rational_number).to eq(RationalNumber.new(3,1))
        expect(node(:node_3).rational_number).to eq(RationalNumber.new(4,1))
      end

      it "should move conflicting nodes and their children when setting position" do
        node_2 = node(:node_2)
        node_2.move_to_position(1)
        node_2.save!
        expect(node(:node_2).rational_number).to eq(RationalNumber.new(1,1))
        expect(node(:node_1).rational_number).to eq(RationalNumber.new(2,1))
        expect(node(:node_3).rational_number).to eq(RationalNumber.new(3,1))
      end

      it "should move conflicting nodes and their children when setting nv/dv trough function" do
        node_2 = node(:node_2)
        node_2.move_to_rational_number(1,1)
        node_2.save!
        expect(node(:node_2).rational_number).to eq(RationalNumber.new(1,1))
        expect(node(:node_1).rational_number).to eq(RationalNumber.new(2,1))
        expect(node(:node_3).rational_number).to eq(RationalNumber.new(3,1))
      end

      it "should move conflicting nodes and their children when setting nv/dv trough function" do
        node_3 = node(:node_3)
        node_3.move_to_rational_number(5,2)
        node_3.save!
        expect(node(:node_3).rational_number).to eq(RationalNumber.new(5,2))
        expect(node(:node_2_1).rational_number).to eq(RationalNumber.new(8,3))
        expect(node(:node_2_2).rational_number).to eq(RationalNumber.new(11,4))
      end

    end

    describe "#move_to_top" do
      it "should return true when attempting to move the first sibling" do
        expect(node(:node_1).move_to_top).to eq(true)
        expect(node(:node_1_1).move_to_top).to eq(true)
      end

      it "should be able to move the last sibling to the top" do
        first_node = node(:node_1)
        last_node  = node(:node_3)
        last_node.move_to_top
        first_node.reload
        expect(last_node).to be_at_top
        expect(first_node).not_to be_at_top
        expect(first_node.higher_siblings.to_a).to eq([last_node])
        expect(last_node.lower_siblings.to_a).to eq([first_node, node(:node_2)])

        expect(first_node.rational_number).to eq(RationalNumber.new(2,1))
        expect(last_node.rational_number).to eq(RationalNumber.new(1,1))
      end

      it 'should rekey the children of a node when moving the node' do
        node_2_4_1_prev_keys   = node(:node_2_4_1).rational_number
        node_2_4_2_prev_keys   = node(:node_2_4_2).rational_number
        node_2 = node(:node_2)
        node_2.move_to_top
        node_2.reload
        expect(node_2).to be_at_top

        expect(node(:node_2_4_1).rational_number).not_to    eq(node_2_4_1_prev_keys)
        expect(node(:node_2_4_2).rational_number).not_to    eq(node_2_4_2_prev_keys)
        expect(node(:node_2_4_1).rational_number).to        eq(RationalNumber.new(20,11))
        expect(node(:node_2_4_2).rational_number).to        eq(RationalNumber.new(31,17))
      end

    end

    describe "#move_to_bottom" do
      it "should return true when attempting to move the last sibling" do
        expect(node(:node_3).move_to_bottom).to eq(true)
        expect(node(:node_1_2).move_to_bottom).to eq(true)
      end

      it "should be able to move the first sibling to the bottom" do
        first_node = node(:node_1)
        middle_node = node(:node_2)
        last_node = node(:node_3)
        first_node.move_to_bottom
        middle_node.reload
        last_node.reload
        expect(first_node).not_to be_at_top
        expect(first_node).to be_at_bottom
        expect(last_node).not_to be_at_bottom
        expect(last_node).not_to be_at_top
        expect(middle_node).to be_at_top
        expect(first_node.lower_siblings.to_a).to eq([])
        expect(last_node.higher_siblings.to_a).to eq([middle_node])

        expect(middle_node.rational_number).to eq(RationalNumber.new(1,1))
        expect(last_node.rational_number).to eq(RationalNumber.new(2,1))
        expect(first_node.rational_number).to eq(RationalNumber.new(3,1))
      end

      it 'should rekey the children of a node when moving the node' do
        node_2_4_1_prev_keys   = node(:node_2_4_1).rational_number
        node_2_4_2_prev_keys   = node(:node_2_4_2).rational_number
        node_2 = node(:node_2)
        node_2.move_to_bottom
        node_2.reload
        expect(node_2).to be_at_bottom

        expect(node(:node_2_4_1).rational_number).not_to    eq(node_2_4_1_prev_keys)
        expect(node(:node_2_4_2).rational_number).not_to    eq(node_2_4_2_prev_keys)
        expect(node(:node_2_4_1).rational_number).to        eq(RationalNumber.new(42,11))
        expect(node(:node_2_4_2).rational_number).to        eq(RationalNumber.new(65,17))
      end
    end

    describe "#move_up" do
      it "should correctly move nodes up" do
        node(:node_2_3).move_up
        expect(node(:node_2).children).to eq([node(:node_2_1), node(:node_2_3), node(:node_2_2), node(:node_2_4)])
      end
    end

    describe "#move_down" do
      it "should correctly move nodes down" do
        node(:node_2_3).move_down
        expect(node(:node_2).children).to eq([node(:node_2_1), node(:node_2_2), node(:node_2_4), node(:node_2_3)])
      end
    end
  end # moving nodes with small tree

  describe "querying the tree" do
    before(:each) do
      setup_tree <<-ENDTREE
        - node_1:
          - node_1_1
          - node_1_2:
            - node_1_2_1:
              - node_1_2_1_1
              - node_1_2_1_2
            - node_1_2_2:
              - node_1_2_2_1
        - node_2:
          - node_2_1:
            - node_2_1_1
        - node_3:
          - node_3_1
          - node_3_2
      ENDTREE
    end
    it "should get the tree under the given node" do
      expect(node(:node_1).tree.all).to eq([node(:node_1_1), node(:node_1_2), node(:node_1_2_1), node(:node_1_2_1_1), node(:node_1_2_1_2), node(:node_1_2_2), node(:node_1_2_2_1)])
      expect(node(:node_2).tree.all).to eq([node(:node_2_1), node(:node_2_1_1)])
      expect(node(:node_3).tree.all).to eq([node(:node_3_1), node(:node_3_2)])

      expect(node(:node_1).tree_and_self.all).to eq([node(:node_1), node(:node_1_1), node(:node_1_2), node(:node_1_2_1), node(:node_1_2_1_1), node(:node_1_2_1_2), node(:node_1_2_2), node(:node_1_2_2_1)])
      expect(node(:node_2).tree_and_self.all).to eq([node(:node_2), node(:node_2_1), node(:node_2_1_1)])
      expect(node(:node_3).tree_and_self.all).to eq([node(:node_3), node(:node_3_1), node(:node_3_2)])
    end
  end

  describe "when rekeying" do
    before(:each) do
      setup_tree <<-ENDTREE
        - node_1
        - node_2:
          - node_2_1
          - node_2_2
          - node_2_3
          - node_2_4:
            - node_2_4_1
            - node_2_4_2
            - node_2_4_3
        - node_3
      ENDTREE
    end
    it "should rekey the entire tree" do
      # Force two gaps in the order
      node_3 = node(:node_3)
      node_3.move_to_position(8, {:force => true})
      node_3.save_with_force_rational_numbers!
      expect(node(:node_3).rational_number).to      eq(RationalNumber.new(8,1))

      node_2 = node(:node_2)
      node_2.move_to_position(4, {:force => true})
      node_2.save_with_force_rational_numbers!
      expect(node(:node_2).rational_number).to      eq(RationalNumber.new(4,1))

      RationalNumberedNode.rekey_all!

      # all nodes should still have their respective positions

      expect(node(:node_1).rational_number).to      eq(RationalNumber.new(1,1))
      expect(node(:node_2).rational_number).to      eq(RationalNumber.new(2,1))
      expect(node(:node_3).rational_number).to      eq(RationalNumber.new(3,1))
      expect(node(:node_2_1).rational_number).to    eq(RationalNumber.new(5,2))
      expect(node(:node_2_2).rational_number).to    eq(RationalNumber.new(8,3))
      expect(node(:node_2_3).rational_number).to    eq(RationalNumber.new(11,4))
      expect(node(:node_2_4).rational_number).to    eq(RationalNumber.new(14,5))
      expect(node(:node_2_4_1).rational_number).to  eq(RationalNumber.new(31,11))
      expect(node(:node_2_4_2).rational_number).to  eq(RationalNumber.new(48,17))
      expect(node(:node_2_4_3).rational_number).to  eq(RationalNumber.new(65,23))
    end
  end

  describe "testing validations" do
    before(:each) do
      setup_tree <<-ENDTREE
        - node_1
        - node_2:
          - node_2_1
        - node_3
      ENDTREE
    end

    it "should fail validation when trying to set invalid nv/dv (parent not found)" do
      node_to_move = node(:node_2_1)
      node_to_move.rational_number_nv = 65
      node_to_move.rational_number_dv = 23
      node_to_move.save
      expect(node_to_move).not_to be_valid
    end

    it "should fail validation when trying to nv/dv resulting in cyclic relation" do
      node_to_move = node(:node_2)
      node_to_move.rational_number_nv = 13
      node_to_move.rational_number_dv = 15
      node_to_move.save
      expect(node_to_move).not_to be_valid
    end

  end # describe "testing validations"

  describe "testing with timestamped nodes" do
    before(:each) do
      setup_tree <<-ENDTREE
        - node_1:
          - node_1_1
          - node_1_2
        - node_2:
          - node_2_1
          - node_2_2
          - node_2_3
        - node_3
      ENDTREE
    end

    describe "siblings should keep timestamp, node should be updated" do
      subject { RationalNumberedTimestampNode }

      it "when inserting a new node" do
        node_2_1_new = RationalNumberedTimestampNode.new(:name => "node_2_1_new")
        node_2_1_new.rational_number_nv = node(:node_2_1).rational_number.nv
        node_2_1_new.rational_number_dv = node(:node_2_1).rational_number.dv
        prev_updated_at = node(:node_2_1).updated_at
        Timecop.freeze(Time.now + 30.minutes) do
          node_2_1_new.save
          expect(node_2_1_new.updated_at).to       be_within(2.seconds).of(Time.now)
          expect(node(:node_2_1).updated_at).to    eq(prev_updated_at)
        end
      end

      it "when moving a node up" do
        prev_updated_at = node(:node_2_2).updated_at
        Timecop.freeze(Time.now + 30.minutes) do
          node(:node_2_3).move_up
          expect(node(:node_2_3).updated_at).to    be_within(2.seconds).of(Time.now)
          expect(node(:node_2_2).updated_at).to    eq(prev_updated_at)
        end
      end

      it "when moving a node down" do
        prev_updated_at = node(:node_2_2).updated_at
        Timecop.freeze(Time.now + 30.minutes) do
          node(:node_2_1).move_down
          expect(node(:node_2_1).updated_at).to    be_within(2.seconds).of(Time.now)
          expect(node(:node_2_2).updated_at).to    eq(prev_updated_at)
        end
      end

      it "when moving a to the bottom of a tree" do
        prev_updated_at = node(:node_2_2).updated_at
        Timecop.freeze(Time.now + 30.minutes) do
          node(:node_2_1).move_to_bottom
          expect(node(:node_2_1).updated_at).to    be_within(2.seconds).of(Time.now)
          expect(node(:node_2_2).updated_at).to    eq(prev_updated_at)
        end
      end

      it "when moving a to the top of a tree" do
        prev_updated_at = node(:node_2_2).updated_at
        Timecop.freeze(Time.now + 30.minutes) do
          node(:node_2_3).move_to_top
          expect(node(:node_2_3).updated_at).to    be_within(2.seconds).of(Time.now)
          expect(node(:node_2_2).updated_at).to    eq(prev_updated_at)
        end
      end

      it "when moving a node to a new parent" do
        original_root = node(:node_1)
        other_root    = node(:node_2)
        child         = node(:node_1_2)
        expect(child.position).to eq(2)
        prev_updated_at = node(:node_2_2).updated_at
        Timecop.freeze(Time.now + 30.minutes) do
          child.parent = other_root
          child.save
          child.reload
          expect(node(:node_2_2).updated_at).to    eq(prev_updated_at)
        end
      end

      it "when removing a node" do
        prev_updated_at = node(:node_2_2).updated_at
        Timecop.freeze(Time.now + 30.minutes) do
          node(:node_2_1).destroy
          expect(node(:node_2_2).updated_at).to    eq(prev_updated_at)
        end
      end

    end # "on siblings it"

    describe "when disabling auto_tree_timestamping, timestamps should be updated" do
      subject { RationalNumberedTimestampNodeDisabledTimestamp }

      it "when inserting a new node" do
        node_2_1_new = RationalNumberedTimestampNodeDisabledTimestamp.create(:name => "node_2_1_new")
        Timecop.freeze(Time.now + 30.minutes) do
          node_2_1_new.move_to_rational_number(node(:node_2_1).rational_number_nv, node(:node_2_1).rational_number_dv)
          node_2_1_new.save
          expect(node_2_1_new.updated_at).to       be_within(2.seconds).of(Time.now)
          expect(node(:node_2_1).updated_at).to    be_within(2.seconds).of(Time.now)
        end
      end

      it "when moving a node up" do
        prev_updated_at = node(:node_2_2).updated_at
        Timecop.freeze(Time.now + 30.minutes) do
          node(:node_2_3).move_up
          expect(node(:node_2_3).updated_at).to    be_within(2.seconds).of(Time.now)
          expect(node(:node_2_2).updated_at).to    be_within(2.seconds).of(Time.now)
        end
      end

      it "when moving a node down" do
        prev_updated_at = node(:node_2_2).updated_at
        Timecop.freeze(Time.now + 30.minutes) do
          node(:node_2_1).move_down
          expect(node(:node_2_1).updated_at).to    be_within(2.seconds).of(Time.now)
          expect(node(:node_2_2).updated_at).to    be_within(2.seconds).of(Time.now)
        end
      end

      it "when moving a to the bottom of a tree" do
        prev_updated_at = node(:node_2_2).updated_at
        Timecop.freeze(Time.now + 30.minutes) do
          node(:node_2_1).move_to_bottom
          expect(node(:node_2_1).updated_at).to    be_within(2.seconds).of(Time.now)
          expect(node(:node_2_2).updated_at).to    be_within(2.seconds).of(Time.now)
        end
      end

      it "when moving a to the top of a tree" do
        prev_updated_at = node(:node_2_2).updated_at
        Timecop.freeze(Time.now + 30.minutes) do
          node(:node_2_3).move_to_top
          expect(node(:node_2_3).updated_at).to    be_within(2.seconds).of(Time.now)
          expect(node(:node_2_2).updated_at).to    be_within(2.seconds).of(Time.now)
        end
      end

      it "when moving a node to a new parent" do
        original_root = node(:node_1)
        other_root    = node(:node_2)
        child         = node(:node_2_1)
        prev_updated_at = node(:node_2_2).updated_at
        Timecop.freeze(Time.now + 30.minutes) do
          child.parent = other_root
          child.save
          child.reload
          expect(node(:node_2_2).updated_at).to    be_within(2.seconds).of(Time.now)
        end
      end

      it "when removing a node" do
        prev_updated_at = node(:node_2_2).updated_at
        Timecop.freeze(Time.now + 30.minutes) do
          node(:node_2_1).destroy
          expect(node(:node_2_2).updated_at).to    be_within(2.seconds).of(Time.now)
        end
      end

    end # "on siblings it"
  end # "testing with timestamped nodes"

  # describe "testing moving within siblings" do
  #   before(:each) do
  #     setup_tree <<-ENDTREE
  #       - node_1
  #       - node_2:
  #         - node_2_1
  #         - node_2_2
  #       - node_3
  #     ENDTREE
  #   end
  #   it "should move node_2_2 " do
  #   end

  # end

end # Mongoid::Tree::RationalNumbering
