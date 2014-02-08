#= require ../model
#= require ./association_curator

for k in Batman.AssociationCurator.availableAssociations
  do (k) =>
    Batman.Model[k] = (label, scope) ->
      Batman.initializeObject(this)
      collection = @_batman.associations ||= new Batman.AssociationCurator(this)
      collection.add new Batman["#{Batman.helpers.capitalize(k)}Association"](this, label, scope)

