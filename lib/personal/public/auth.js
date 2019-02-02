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
          window.location.href="/auth"
          console.log(data)
        }, "json"
      ) 
  }
  
  function trueLogin(masked) {
    var box = makeBoxBase64(masked)
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
        window.location.href="/auth"
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
  