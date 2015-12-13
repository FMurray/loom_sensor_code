
device.on("senddata", function(data) {
  // Set URL to your web service
  local url = "http://admin.loomgrown.com:8000/sensors/data/";

  // Set Content-Type header to json
  local headers = { "Content-Type": "application/json" };

  // encode data and log
  local body = http.jsonencode(data);
  server.log(body);
  
  // send data to your web service
  http.post(url, headers, body).sendsync();
});