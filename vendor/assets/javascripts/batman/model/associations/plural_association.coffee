#= require ./association

class Batman.PluralAssociation extends Batman.Association
  proxyClass: Batman.AssociationSet
  isSingular: false

  constructor: ->
    super
    @_resetSetHashes()

  setForRecord: (record) ->
    indexValue = @indexValueForRecord(record)
    childModelSetIndex = @setIndex()
    Batman.Property.withoutTracking =>
      @_setsByRecord.getOrSet record, =>
        # Return an existing set from the value proxies if we have a value
        if indexValue?
          existingValueSet = @_setsByValue.get(indexValue)
          if existingValueSet?
            return existingValueSet

        # Otherwise, add a new set to the record proxies, and stick it in the value proxies if we have a value.
        newSet = @proxyClassInstanceForKey(indexValue)
        if indexValue?
          @_setsByValue.set indexValue, newSet
        newSet

    if indexValue?
      childModelSetIndex.get(indexValue)
    else
      @_setsByRecord.get(record)

  setForKey: Batman.Property.wrapTrackingPrevention (indexValue) ->
    foundSet = undefined
    # If we have a set for a record who has the value matching the one passed in, return it.
    @_setsByRecord.forEach (record, set) =>
      return if foundSet?
      foundSet = set if @indexValueForRecord(record) == indexValue
    if foundSet?
      foundSet.foreignKeyValue = indexValue
      return foundSet

    # Otherwise, set a new set into the value keyd sets which will get picked up in `setForRecord`.
    @_setsByValue.getOrSet indexValue, => @proxyClassInstanceForKey(indexValue)

  proxyClassInstanceForKey: (indexValue) ->
    new @proxyClass(indexValue, this)

  getAccessor: (self, model, label) ->
    return unless self.getRelatedModel()

    # Check whether the relation has already been set on this model
    if setInAttributes = self.getFromAttributes(this)
      setInAttributes
    else
      relatedRecords = self.setForRecord(this)
      self.setIntoAttributes(this, relatedRecords)

      Batman.Property.withoutTracking =>
        if self.options.autoload and not @isNew() and not relatedRecords.loaded
          relatedRecords.load (error, records) -> throw error if error

      relatedRecords

  parentSetIndex: ->
    @parentIndex ||= @model.get('loaded').indexedByUnique(@primaryKey)
    @parentIndex

  setIndex: ->
    @index ||= new Batman.AssociationSetIndex(this, @[@indexRelatedModelOn])
    @index

  indexValueForRecord: (record) -> record.get(this.primaryKey)

  reset: ->
    super
    @_resetSetHashes()

  _resetSetHashes: ->
    @_setsByRecord = new Batman.SimpleHash
    @_setsByValue = new Batman.SimpleHash
