// public/javascripts/application.js
$(function() {

  $("form.delete").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();

    var ok = confirm("Are you sure? This cannot be undone!");
    if (ok) {
      var form = $(this);

      var request = $.ajax({
        url: form.attr("action"),
        method: form.attr("method")
      });

      request.done(function(data, textStatus, jqXHR) {
        if (jqXHR.status === 204) {
          form.parent("tr").remove();
        } else if (jqXHR.status === 200) {
          document.location = data;
        }
      });
    }
  });

  $("a.edit").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();

    var ok = confirm("Category exists with this name and it will be overwritten. Are you sure? This cannot be undone!");
    if (ok) {
      var form = $(this);

      var request = $.ajax({
        url: form.attr("action"),
        method: form.attr("method")
      });

      request.done(function(data, textStatus, jqXHR) {
        if (jqXHR.status === 204) {
          form.parent("tr").remove();
        } else if (jqXHR.status === 200) {
          document.location = data;
        }
      });
    }
  });

});
