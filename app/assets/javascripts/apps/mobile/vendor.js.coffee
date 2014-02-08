#= require zepto
#= require zepto.cookie
#= require zepto.scrollend
#= require hammer
#= require audio5
#= require moment-with-langs
#= require ../../locales

#= require batman/batman
#= require batman/platform/solo
#= require batman/extras/batman.i18n
#= require batman/extras/batman.rails
#= require_self

Batman.I18N.set 'locales', I18n.translations
Batman.I18N.set 'locale', data.locale
Batman.config.translations = true
moment.lang(data.locale)