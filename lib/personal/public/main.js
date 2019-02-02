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
