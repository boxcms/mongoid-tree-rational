# mongoid-tree [![Build Status](https://secure.travis-ci.org/boxcms/mongoid-tree-rational.png?branch=master)](https://travis-ci.org/boxcms/mongoid-tree-rational) [![Dependency Status](https://gemnasium.com/boxcms/mongoid-tree-rational.png)](https://gemnasium.com/boxcms/mongoid-tree-rational) [![Coverage Status](https://coveralls.io/repos/boxcms/mongoid-tree-rational/badge.png)](https://coveralls.io/r/boxcms/mongoid-tree-rational)

A tree structure for Mongoid documents using rational numbers and materialized path pattern

## Requirements

* mongoid (~> 3.0)

This version will only support mongoid 3.0+

## Install

To install mongoid_tree_rational, simply add it to your Gemfile:

    gem 'mongoid-tree-rational', :require => 'mongoid/tree'

In order to get the latest development version of mongoid-tree:

    gem 'mongoid-tree-rational', :git => 'git://github.com/boxcms/mongoid-tree-rational', :require => 'mongoid/tree'

You might want to remove the `:require => 'mongoid/tree'` option and explicitly `require 'mongoid/tree'` where needed and finally run

    bundle install


## Usage

```ruby
class Node
  include Mongoid::Document
  include Mongoid::Tree
  include Mongoid::Tree::RationalNumbering
end
```

### Utility methods

There are several utility methods that help getting to other related documents in the tree:

```ruby
Node.root
Node.roots
Node.leaves

node.root
node.parent
node.children
node.ancestors
node.ancestors_and_self
node.descendants
node.descendants_and_self
node.siblings
node.siblings_and_self
node.leaves
```

In addition it's possible to check certain aspects of the document's position in the tree:

```ruby
node.root?
node.leaf?
node.depth
node.ancestor_of?(other)
node.descendant_of?(other)
node.sibling_of?(other)
```

See `Mongoid::Tree` for more information on these methods.


### Ordering

`Mongoid::Tree` doesn't order children by default. To enable ordering of tree nodes include the `Mongoid::Tree::RationalNumbering` or the `Mongoid::Tree::Ordering` module.


#### By rational numbers

To use rational ordering, include the `Mongoid::Tree::RationalNumbering` module. This will add a `position` field to your document and provide additional utility methods:

While rational numbering requires more processing when saving, it does give the benefit of querying an entire tree in one go.


Mathematical details about rational numbers in nested trees can be found here: [http://arxiv.org/pdf/0806.3115v1.pdf](http://arxiv.org/pdf/0806.3115v1.pdf)


```ruby
node.lower_siblings
node.higher_siblings
node.first_sibling_in_list
node.last_sibling_in_list
node.siblings_between(other_node)

node.tree # get the entire tree under the node (Triggers 1 query only! Hurray)
node.tree_and_self # # get the entire tree under the node including node

node.move_up
node.move_down
node.move_to_top
node.move_to_bottom
node.move_above(other)
node.move_below(other)

node.at_top?
node.at_bottom?
```

Example:

```ruby
class Node
  include Mongoid::Document
  include Mongoid::Tree
  include Mongoid::Tree::RationalNumbering
end
```

There are one additional class function
```ruby
Node.rekey_all! # Will iterate over the entire tree and rekey every single node.
                # Please note that this might take a while for a large tree.
                # Do this in a background worker or rake task.
end
```

You can get the entire tree in one go like this:

```ruby
# - node_1
#    - node_1_1
#    - node_1_2
# - node_2
#   - node_2_1
#     - node_2_1_1
#     - node_2_1_2
#   - node_2_2
#     - node_2_2_1
#     - node_2_2_2

Node.all  # Get the entire tree
# -> [node_1, node_1_1, node_1_2, node_2, node_2_1, node_2_1_1, node_2_1_2, node_2_2, node_2_2_1, node_2_2_2]
end
```

See `Mongoid::Tree::RationalNumbering` for more information on these methods.

#### By 0-based integer (simple)

To use simple ordering, include the `Mongoid::Tree::Ordering` module. This will add a `position` field to your document and provide additional utility methods:

```ruby
node.lower_siblings
node.higher_siblings
node.first_sibling_in_list
node.last_sibling_in_list

node.move_up
node.move_down
node.move_to_top
node.move_to_bottom
node.move_above(other)
node.move_below(other)

node.at_top?
node.at_bottom?
```

Example:

```ruby
class Node
  include Mongoid::Document
  include Mongoid::Tree
  include Mongoid::Tree::Ordering
end
```

See `Mongoid::Tree::Ordering` for more information on these methods.

### Traversal

It's possible to traverse the tree using different traversal methods using the `Mongoid::Tree::Traversal` module.

Example:

```ruby
class Node
  include Mongoid::Document
  include Mongoid::Tree
  include Mongoid::Tree::Traversal
end

node.traverse(:breadth_first) do |n|
  # Do something with Node n
end
```

### Destroying

`Mongoid::Tree` does not handle destroying of nodes by default. However it provides several strategies that help you to deal with children of deleted documents. You can simply add them as `before_destroy` callbacks.

Available strategies are:

* `:nullify_children` -- Sets the children's parent_id to null
* `:move_children_to_parent` -- Moves the children to the current document's parent
* `:destroy_children` -- Destroys all children by calling their `#destroy` method (invokes callbacks)
* `:delete_descendants` -- Deletes all descendants using a database query (doesn't invoke callbacks)

Example:

```ruby
class Node
  include Mongoid::Document
  include Mongoid::Tree

  before_destroy :nullify_children
end
```


### Callbacks

There are two callbacks that are called before and after the rearranging process. This enables you to do additional computations after the documents position in the tree is updated. See `Mongoid::Tree` for details.

Example:

```ruby
class Page
  include Mongoid::Document
  include Mongoid::Tree

  after_rearrange :rebuild_path

  field :slug
  field :path

  private

  def rebuild_path
    self.path = self.ancestors_and_self.collect(&:slug).join('/')
  end
end
```

### Validations

`Mongoid::Tree` currently does not validate the document's children or parent associations by default. To explicitly enable validation for children and parent documents it's required to add a `validates_associated` validation.

Example:

```ruby
class Node
  include Mongoid::Document
  include Mongoid::Tree

  validates_associated :parent, :children
end
```

## Build Status

mongoid-tree is on [Travis CI](http://travis-ci.org/boxcms/mongoid-tree-rational) running the specs on Ruby Head, Ruby 1.9.3, JRuby (1.9 mode), and Rubinius (1.9 mode).

## Known issues

See [github.com/boxcms/mongoid-tree-rational/issues](https://github.com/boxcms/mongoid-tree-rational/issues)


## Repository

See [github.com/boxcms/mongoid-tree-rational](https://github.com/boxcms/mongoid-tree-rational) and feel free to fork it!


## MongoMapper version

Have a look here: [github.com/leifcr/mm-tree](https://github.com/leifcr/mm-tree)

## Contributors

See a list of all contributors at [github.com/boxcms/mongoid-tree-rational/contributors](https://github.com/boxcms/mongoid-tree-rational/contributors). Thanks!

A huge thanks to [Benedikt Deicke](https://github.com/benedikt) for all the work on mongoid-tree. This rational number version is based on his work

## Copyright

See LICENSE for details.
