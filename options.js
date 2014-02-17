// Saves options to localStorage.
function save_options() {
  var accessTokenField = document.querySelector("#access-token");
  localStorage.setItem('accessToken', accessTokenField.value);

  var refreshRate = document.querySelector("#refresh-rate");
  localStorage.setItem('refreshRate', refreshRate.value);

  // Update status to let user know options were saved.
  var status = document.querySelector(".status");
  status.innerHTML = "saved";
  setTimeout(function() {
    status.innerHTML = "";
  }, 750);
}

// Restores select box state to saved value from localStorage.
function restore_options() {
  var accessToken = localStorage.getItem('accessToken');
  var accessTokenField = document.querySelector("#access-token");
  accessTokenField.value = accessToken;

  var refreshRate = localStorage.getItem('refreshRate');
  var refreshRateField = document.querySelector("#refresh-rate");
  refreshRateField.value = refreshRate;
}
document.addEventListener('DOMContentLoaded', restore_options);
document.querySelector('.save').addEventListener('click', save_options);
