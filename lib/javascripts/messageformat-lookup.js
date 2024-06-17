(function () {
  I18n.messageFormat = function (key, options) {
    var message = I18n._mfMessages.hasMessage(
      key,
      I18n._mfMessages.locale,
      I18n._mfMessages.defaultLocale
    );
    if (message) {
      try {
        return I18n._mfMessages.get(key, options);
      } catch (err) {
        return err.message;
      }
    } else {
      return "Missing Key: " + key;
    }
  };
})();
