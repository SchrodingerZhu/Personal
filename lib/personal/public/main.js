function setCookie(name, value) { 
  var exp = new Date(); 
  exp.setTime(exp.getTime() + 60 * 60 * 1000); 
  document.cookie = name + "=" + escape(value) + ";expires=" + exp.toGMTString() + ";path=/"; 
} 

function getCookie(name) { 
  var arr, reg = new RegExp("(^| )" + name + "=([^;]*)(;|$)"); 

  if (arr = document.cookie.match(reg)) 

      return unescape(arr[2]); 
  else 
      return null; 
} 

function initKeys() {
  var m = sodium.crypto_box_keypair()
  var pri = sodium.to_base64(m.privateKey)
  var pub = sodium.to_base64(m.publicKey)
  setCookie("personal.private", pri)
  setCookie("personal.public", pub)
}

function makebox(msg) {

}

function buildSession(name){
  var json = {
    username: name,
    public_key: getCookie("personal.public")
  }; 
  
  $.post(
    "/auth/handshake",
    JSON.stringify(json),
    function (data){
      console.log(data)
      setCookie("personal.uuid", data.id)
      setCookie("personal.nonce", data.nonce)
      setCookie("personal.server_pub", data.public_key)
    }, "json"
  )
}

function login(password){
  var uuid = getCookie("personal.uuid")
  var nonce = sodium.from_base64(getCookie("personal.nonce"))
  var server_pub = sodium.from_base64(getCookie("personal.server_pub"))
  var private = sodium.from_base64(getCookie("personal.private"))
  var masked = md5(password)
  console.log(masked)
  var box = sodium.to_base64(sodium.crypto_box_easy(masked, nonce, server_pub, private))
  var json = {
      request: "login",
      id: uuid, 
      box: box
  }
  $.post(
    "/auth/handshake",
    JSON.stringify(json),
    function (data){
      console.log(data)
      setCookie("personal.nonce", data.nonce)
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
