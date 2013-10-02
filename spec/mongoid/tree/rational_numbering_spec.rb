require 'spec_helper'

describe Mongoid::Tree::RationalNumbering do

  subject { RationalNumberedNode }

  # it "should verify type of initial rational numbers" do
  #   f_nv  = RationalNumberedNode.fields['rational_number_nv']
  #   f_dv  = RationalNumberedNode.fields['rational_number_dv']
  #   f_snv = RationalNumberedNode.fields['rational_number_snv']
  #   f_sdv = RationalNumberedNode.fields['rational_number_sdv']
  #   f_value = RationalNumberedNode.fields['rational_number_value']
  #   expect(f_nv).not_to be_nil
  #   expect(f_nv.options[:type]).to eq(Integer)
  #   expect(f_dv).not_to be_nil
  #   expect(f_dv.options[:type]).to eq(Integer)
  #   expect(f_snv).not_to be_nil
  #   expect(f_snv.options[:type]).to eq(Integer)
  #   expect(f_sdv).not_to be_nil
  #   expect(f_sdv.options[:type]).to eq(Integer)
  #   expect(f_value).not_to be_nil
  #   expect(f_value.options[:type]).to eq(Float)
  # end

  # describe "for roots" do
  #   it "should create a root node with initial rational numbers" do
  #     a = RationalNumberedNode.create(:name => "a")
  #     expect(a.rational_number).to    eq(RationalNumber.new(1,1,2,1))
  #   end

  #   it "should create two root nodes with initial rational numbers" do
  #     a = RationalNumberedNode.create(:name => "a")
  #     expect(a.rational_number).to    eq(RationalNumber.new(1,1,2,1))
  #     b = RationalNumberedNode.create(:name => "b")
  #     expect(b.rational_number).to    eq(RationalNumber.new(2,1,3,1))
  #   end
  # end


  # describe "when setting parent/children" do

  #   it "should set the parent of a node after creating the object" do
  #     a = RationalNumberedNode.create(:name => "a")
  #     b = RationalNumberedNode.create(:name => "b")
  #     b.parent = a
  #     b.save!
  #     expect(a.rational_number).to    eq(RationalNumber.new(1,1,2,1))
  #     expect(b.rational_number).to    eq(RationalNumber.new(3,2,5,3))
  #   end

  #   # TODO
  #   # it "should set the parent when creating the object" do
  #   # end

  #   it "should add children to an existing node" do
  #     a = RationalNumberedNode.create(:name => "a")
  #     b = RationalNumberedNode.create(:name => "b")
  #     a.children << b
  #     expect(a.rational_number).to    eq(RationalNumber.new(1,1,2,1))
  #     expect(b.rational_number).to    eq(RationalNumber.new(3,2,5,3))
  #   end
  # end

  # describe 'when saved' do
  #   before(:each) do

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
  #     ENDTREE
  #   end

  #   it "should assign a rational number to each node" do
  #     expect(node(:node_1).rational_number).to    eq(RationalNumber.new(1,1,2,1))
  #     expect(node(:node_2).rational_number).to    eq(RationalNumber.new(2,1,3,1))
  #     expect(node(:node_1_1).rational_number).to  eq(RationalNumber.new(3,2,5,3))
  #     expect(node(:node_1_2).rational_number).to  eq(RationalNumber.new(5,3,7,4))
  #     expect(node(:node_2_1).rational_number).to  eq(RationalNumber.new(5,2,8,3))
  #     expect(node(:node_2_2).rational_number).to  eq(RationalNumber.new(8,3,11,4))
  #   end

  #   it "should get the position for each of the nodes" do
  #     expect(node(:node_1).position).to eq(1)
  #     expect(node(:node_1_1).position).to eq(1)
  #     expect(node(:node_1_2).position).to eq(2)
  #   end

  #   it "should move a node to the end of a list when it is moved to a new parent" do
  #     original_root = node(:node_1)
  #     other_root    = node(:node_2)
  #     child         = node(:node_1_2)
  #     expect(child.position).to eq(2)
  #     child.parent = other_root
  #     child.save
  #     child.reload
  #     expect(child.position).to eq(3)
  #   end

  #   it "should correctly reposition siblings when one of them is removed" do
  #     rational_node_1_1 = node(:node_1_1).rational_number
  #     node(:node_1_1).destroy
  #     expect(node(:node_1_2).position).to eq(1)
  #     expect(node(:node_1_2).rational_number).to eq(RationalNumber.new(3,2,5,3))
  #   end

  #   it "should correctly reposition siblings when one of them is added as a child of another parent" do
  #     node(:node_2).children << node(:node_1_1)
  #     expect(node(:node_1_2).position).to eq(1)
  #     expect(node(:node_1_2).rational_number).to eq(RationalNumber.new(3,2,5,3))
  #   end

  #   it "should correctly reposition siblings when the parent is changed" do
  #     n = node(:node_1_1)
  #     n.parent = node(:node_2)
  #     n.save!
  #     expect(node(:node_1_2).position).to eq(1)
  #     expect(node(:node_1_2).rational_number).to eq(RationalNumber.new(3,2,5,3))
  #   end

  #   it "should not reposition siblings when it's not needed" do
  #     new_node = RationalNumberedNode.new(:name => 'new')
  #     new_node.parent = node(:node_1)
  #     expect(new_node).not_to receive(:rekey_former_siblings)
  #     new_node.save!
  #   end

  # end

  # describe 'destroy strategies' do
  #   # before(:each) do
  #   #   setup_tree <<-ENDTREE
  #   #     - root:
  #   #       - child:
  #   #         - subchild
  #   #       - other_child
  #   #     - other_root
  #   #   ENDTREE
  #   # end

  #   # describe ':move_children_to_parent' do
  #   #   it "should set its childen's parent_id to the documents parent_id" do
  #   #     node(:child).move_children_to_parent
  #   #     node(:child).should be_leaf
  #   #     node(:root).children.to_a.should == [node(:child), node(:other_child), node(:subchild)]
  #   #   end
  #   # end
  # end

  # describe 'utility methods' do
  #   before(:each) do
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
  #   end

  #   describe '#lower_siblings' do
  #     it "should return a collection of siblings lower on the list" do
  #       expect(node(:node_1).lower_siblings.to_a).to        eq([node(:node_2), node(:node_3)])
  #       expect(node(:node_2).lower_siblings.to_a).to        eq([node(:node_3)])
  #       expect(node(:node_3).lower_siblings.to_a).to        eq([])
  #       expect(node(:node_1_1).lower_siblings.to_a).to      eq([node(:node_1_2), node(:node_1_3)])
  #       expect(node(:node_2_2).lower_siblings.to_a).to      eq([])
  #       expect(node(:node_1_1_1).lower_siblings.to_a).to    eq([])
  #       expect(node(:node_1_1_1_1).lower_siblings.to_a).to  eq([])
  #     end
  #   end

  #   describe '#higher_siblings' do
  #     it "should return a collection of siblings lower on the list" do
  #       expect(node(:node_1).higher_siblings.to_a).to   eq([])
  #       expect(node(:node_2).higher_siblings.to_a).to   eq([node(:node_1)])
  #       expect(node(:node_3).higher_siblings.to_a).to   eq([node(:node_1), node(:node_2)])
  #       expect(node(:node_1_1).higher_siblings.to_a).to eq([])
  #       expect(node(:node_1_2).higher_siblings.to_a).to eq([node(:node_1_1)])
  #     end
  #   end

  #   describe '#at_top?' do
  #     it "should return true when the node is first in the list" do
  #       expect(node(:node_1)).to    be_at_top
  #       expect(node(:node_1_1)).to  be_at_top
  #     end

  #     it "should return false when the node is not first in the list" do
  #       expect(node(:node_2)).not_to   be_at_top
  #       expect(node(:node_3)).not_to   be_at_top
  #       expect(node(:node_1_2)).not_to be_at_top
  #     end
  #   end

  #   describe '#at_bottom?' do
  #     it "should return true when the node is last in the list" do
  #       expect(node(:node_3)).to   be_at_bottom
  #       expect(node(:node_1_3)).to be_at_bottom
  #     end

  #     it "should return false when the node is not last in the list" do
  #       expect(node(:node_1)).not_to   be_at_bottom
  #       expect(node(:node_2)).not_to   be_at_bottom
  #       expect(node(:node_1_1)).not_to be_at_bottom
  #     end
  #   end

  #   describe '#last_sibling_in_list' do
  #     it "should return the last sibling in the list containing the current sibling" do
  #       expect(node(:node_1).last_sibling_in_list).to eq(node(:node_3))
  #       expect(node(:node_2).last_sibling_in_list).to eq(node(:node_3))
  #       expect(node(:node_3).last_sibling_in_list).to eq(node(:node_3))
  #     end
  #   end

  #   describe '#first_sibling_in_list' do
  #     it "should return the first sibling in the list containing the current sibling" do
  #       expect(node(:node_1).first_sibling_in_list).to eq(node(:node_1))
  #       expect(node(:node_2).first_sibling_in_list).to eq(node(:node_1))
  #       expect(node(:node_3).first_sibling_in_list).to eq(node(:node_1))
  #     end
  #   end

  #   describe '#ancestors' do
  #     it "should be returned in the correct order" do
  #       setup_tree <<-ENDTREE
  #         - root:
  #           - level_1_a
  #           - level_1_b:
  #             - level_2_a:
  #               - leaf
  #       ENDTREE

  #       expect(node(:leaf).ancestors.to_a).to eq([node(:root), node(:level_1_b), node(:level_2_a)])
  #     end

  #     it "should return the ancestors in correct order after rearranging" do
  #       setup_tree <<-ENDTREE
  #         - node_1:
  #           - node_1_1:
  #             - node_1_1_1
  #       ENDTREE

  #       node_1_1 = node(:node_1_1)
  #       node_1_1.parent = nil
  #       node_1_1.save!

  #       node_1 = node(:node_1)
  #       node_1.parent = node(:node_1_1)
  #       node_1.save!

  #       node_1_1_1 = node(:node_1_1_1)
  #       node_1_1_1.parent = node_1
  #       node_1_1_1.save!

  #       expect(node_1_1_1.ancestors.to_a).to eq([node_1_1, node_1])
  #     end
  #   end
  # end

  describe 'moving nodes' do
    before(:each) do
      # setup_tree <<-ENDTREE
      #   - node_1
      #   - node_2
      #   - node_3
      # ENDTREE

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
        - node_3:
          - node_3_1
          - node_3_2
          - node_3_3
      ENDTREE
    end

    describe '#move_below' do

      it 'should verify rational numbers after moving below' do
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
        print_tree(node(:node_1))
        print_tree(node(:node_2))
        expect(node_to_move).to be_at_bottom
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
        node_1_2_1_prev_keys = node(:node_1_2_1).rational_number
        node_1_2_1_2_prev_keys = node(:node_1_2_1_2).rational_number
        node_1_2 = node(:node_1_2)
        node_1_2.move_below(node(:node_2_1))

        expect(node(:node_1_2_1).rational_number).not_to   eq(node_1_2_1_prev_keys)
        expect(node(:node_1_2_1_2).rational_number).not_to eq(node_1_2_1_2_prev_keys)

        expect(node(:node_1_2_1).rational_number).to       eq(RationalNumber.new(13,5))
        expect(node(:node_1_2_1_2).rational_number).to     eq(RationalNumber.new(55,21))
      end
    end

    # describe '#move_above' do
    #   it 'should fix positions within the current list when moving an sibling away from its current parent' do
    #     node_to_move = node(:node_1_1)
    #     node_to_move.move_above(node(:node_2_1))
    #     expect(node(:node_1_2).position).to eq(1)
    #   end

    #   it 'should work when moving to a different parent' do
    #     node_to_move = node(:node_1_1)
    #     new_parent = node(:node_2)
    #     node_to_move.move_above(node(:node_2_1))
    #     node_to_move.reload
    #     expect(node_to_move).to be_at_top
    #     expect(node(:node_2_1)).to be_at_bottom
    #   end

    #   it 'should be able to move the last node above the second node' do
    #     last_node = node(:node_3)
    #     second_node = node(:node_2)
    #     last_node.move_above(second_node)
    #     last_node.reload
    #     second_node.reload
    #     expect(second_node).to be_at_bottom
    #     expect(last_node.higher_siblings.to_a).to eq([node(:node_1)])
    #   end

    #   it 'should be able to move the first node above the last node' do
    #     first_node = node(:node_1)
    #     last_node = node(:node_3)
    #     first_node.move_above(last_node)
    #     first_node.reload
    #     last_node.reload
    #     expect(node(:node_2)).to be_at_top
    #     expect(first_node.higher_siblings.to_a).to eq([node(:node_2)])
    #   end

    #   it 'should rekey the children of a node when moving to a new parent' do
    #     node_1_2_1_prev_keys = node(:node_1_2_1).rational_number
    #     node_1_2_1_2_prev_keys = node(:node_1_2_1_2).rational_number
    #     node_1_2 = node(:node_1_2)
    #     node_1_2.move_above(node(:node_2_1))

    #     print_tree(node(:node_2))

    #     expect(node(:node_1_2_1).rational_number).not_to   eq(node_1_2_1_prev_keys)
    #     expect(node(:node_1_2_1_2).rational_number).not_to eq(node_1_2_1_2_prev_keys)

    #     expect(node(:node_1_2_1).rational_number).to       eq(RationalNumber.new(29,11))
    #     expect(node(:node_1_2_1_2).rational_number).to     eq(RationalNumber.new(55,21))
    #   end

    # end

    # describe "#move_to_top" do
    #   it "should return true when attempting to move the first sibling" do
    #     expect(node(:node_1).move_to_top).to eq(true)
    #     expect(node(:node_1_1).move_to_top).to eq(true)
    #   end

    #   it "should be able to move the last sibling to the top" do
    #     first_node = node(:node_1)
    #     last_node  = node(:node_3)
    #     last_node.move_to_top
    #     first_node.reload
    #     expect(last_node).to be_at_top
    #     expect(first_node).not_to be_at_top
    #     expect(first_node.higher_siblings.to_a).to eq([last_node])
    #     expect(last_node.lower_siblings.to_a).to eq([first_node, node(:node_2)])

    #     expect(first_node.rational_number).to eq(RationalNumber.new(2,1))
    #     expect(last_node.rational_number).to eq(RationalNumber.new(1,1))
    #     puts node(:node_1).rational_number.inspect
    #     puts node(:node_2).rational_number.inspect
    #     puts node(:node_3).rational_number.inspect
    #   end
    # end

    # describe "#move_to_bottom" do
    #   it "should return true when attempting to move the last sibling" do
    #     expect(node(:node_3).move_to_bottom).to eq(true)
    #     expect(node(:node_1_2).move_to_bottom).to eq(true)
    #   end

    #   it "should be able to move the first sibling to the bottom" do
    #     first_node = node(:node_1)
    #     middle_node = node(:node_2)
    #     last_node = node(:node_3)
    #     first_node.move_to_bottom
    #     middle_node.reload
    #     last_node.reload
    #     expect(first_node).not_to be_at_top
    #     expect(first_node).to be_at_bottom
    #     expect(last_node).not_to be_at_bottom
    #     expect(last_node).not_to be_at_top
    #     expect(middle_node).to be_at_top
    #     expect(first_node.lower_siblings.to_a).to eq([])
    #     expect(last_node.higher_siblings.to_a).to eq([middle_node])
    #     puts node(:node_1).rational_number.inspect
    #     puts node(:node_2).rational_number.inspect
    #     puts node(:node_3).rational_number.inspect

    #     expect(middle_node.rational_number).to eq(RationalNumber.new(1,1))
    #     expect(last_node.rational_number).to eq(RationalNumber.new(2,1))
    #     expect(first_node.rational_number).to eq(RationalNumber.new(3,1))
    #   end
    # end

    # describe "#move_up" do
    #   it "should correctly move nodes up" do
    #     node(:node_3_3).move_up
    #     expect(node(:node_3).children).to eq([node(:node_3_1), node(:node_3_3), node(:node_3_2)])
    #   end
    # end

    # describe "#move_down" do
    #   it "should correctly move nodes down" do
    #     node(:node_3_1).move_down
    #     expect(node(:node_3).children).to eq([node(:node_3_2), node(:node_3_1), node(:node_3_3)])
    #   end
    # end
  end # moving nodes around

end # Mongoid::Tree::RationalNumbering
