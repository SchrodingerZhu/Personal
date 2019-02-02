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
        }, "json"
      ) 
  }
  
  function trueLogin(masked) {
    var nonce = sodium.from_base64(getCookie("personal.nonce"))
    var private_key = sodium.from_base64(localStorage["personal.private"])
    var server_pub = sodium.from_base64(getCookie("personal.server_pub"))
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
      }, "json"
    )
  }
  
  function login(password) {
    var masked = md5(password)
    var json = {
      request: "check"
    }
    $.post(
      "/auth/handshake",
      JSON.stringify(json),
      function (data) {
        argon2.verify({ pass: masked, encoded: data.argon2 })
        .then(() => {console.log('OK'); trueLogin(masked); })
        .catch(e => {console.error(e.message, e.code); clearSession()})
      }, "json"
    )
  }
  