class RationalNumber
  include Mongoid::Document
  embedded_in :rational_numberic, polymorphic: true
  
  plugin MongoMapper::Plugins::Dirty
  attr_accessible :nv, :dv, :snv, :sdv, :path, :depth, :position #, :parent_id

  field :nv,  Integer, :default => 0
  field :dv,  Integer, :default => 0
  field :snv, Integer, :default => 0
  field :sdv, Integer, :default => 0
  # field :path, Array # , :typecast => 'ObjectId' # might need to be string instead?
#  key :depth, Integer

  timestamps!

end
