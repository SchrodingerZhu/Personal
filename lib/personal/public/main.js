function setCookie(name, value) {
  document.cookie = name + "=" + escape(value) + "; max-age=1800 ;path=/; httpOnly";
}

function getCookie(name) {
  var arr, reg = new RegExp("(^| )"+ name +"=([^;]*)(;|$)");

  if (arr = document.cookie.match(reg))
    return unescape(arr[2]);
  else
    return null;
}
function buildSession(name) {

  var m = sodium.crypto_box_keypair()
  var pri = sodium.to_base64(m.privateKey)
  var pub = sodium.to_base64(m.publicKey)
  localStorage.setItem("personal.private", pri)
  var json = {
    username: name,
    public_key: pub
  };
    $.post(
      "/auth/handshake",
      JSON.stringify(json),
      function (data) {
        console.log(data)
        window.location.reload()
      }, "json"
    ) 
}

function login(password) {
  var nonce = sodium.from_base64(getCookie("personal.nonce"))
  var private_key = sodium.from_base64(localStorage["personal.private"])
  var server_pub = sodium.from_base64(getCookie("personal.server_pub"))
  var masked = md5(password)
  var box = sodium.to_base64(sodium.crypto_box_easy(masked, nonce, server_pub, private_key))
  var json = {
    request: "login",
    box: box
  }
  $.post(
    "/auth/handshake",
    JSON.stringify(json),
    function (data) {
      console.log(data)
      if(data.login == true) {
        window.location.href="/"
      } else {
        console.log("failed!")
      }
    }, "json"
  )
}


function logout() {
  var json = {
    request: "logout",
  }
  localStorage.removeItem("personal.private")
  $.post(
    "/auth/handshake",
    JSON.stringify(json),
    function (data) {
      console.log(data)
      if(data.logout) {
        window.location.href="/"
      } else {
        console.log("failed!")
      }
    }, "json"
  )
}

function clearSession() {
  var json = {
    request: "clear"
  }
  localStorage.removeItem("personal.private")
  $.post(
    "/auth/handshake",
    JSON.stringify(json),
    function (data) {
      console.log(data)
      window.location.reload()
    }, "json"
  )
}

// function buildSession(name) {
//   session = buildSessionJSON(name);
//   for (var key in session) {
//     console.log(key);
//   }
//   let realsession = await session;
//   setCookie("personal.uuid", session.responseJSON.id)
//   //setCookie("personal.nonce", session.responseJSON.nonce)
//   //setCookie("personal.server_pub", session.responseJSON.public_key)
// }
function buildSessionForm() {
  var username = document.getElementById('username').value
  buildSession(username)
}

function loginForm() {
  var password = document.getElementById('password').value
  login(password)
}