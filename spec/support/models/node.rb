class Node
  include Mongoid::Document
  include Mongoid::Tree
  include Mongoid::Tree::Traversal

  field :name

  # attr_accessible :name
end

class SubclassedNode < Node
end

# Adding ordering on subclasses currently doesn't work as expected.
#
# class OrderedNode < Node
#   include Mongoid::Tree::Ordering
# end
class OrderedNode
  include Mongoid::Document
  include Mongoid::Tree
  include Mongoid::Tree::Traversal
  include Mongoid::Tree::Ordering

  field :name

  # attr_accessible :name
end

class NodeWithEmbeddedDocument < Node
  embeds_one :embedded_document, :cascade_callbacks => true
end

class EmbeddedDocument
  include Mongoid::Document
end


class RationalNumberedNode
  include Mongoid::Document
  include Mongoid::Tree
  include Mongoid::Tree::RationalNumbering

  field :name

  # attr_accessible :name
end

class RationalNumberedTimestampNode
  include Mongoid::Document
  include Mongoid::Tree
  include Mongoid::Tree::RationalNumbering
  include Mongoid::Timestamps

  field :name

  # attr_accessible :name
end

class RationalNumberedTimestampNodeDisabledTimestamp
  include Mongoid::Document
  include Mongoid::Tree
  include Mongoid::Tree::RationalNumbering
  include Mongoid::Timestamps
  rational_number_options({ auto_tree_timestamping: false})

  field :name

  # attr_accessible :name
end
