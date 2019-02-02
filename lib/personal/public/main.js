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
function makeBoxBase64(content) {
  var nonce = sodium.from_base64(getCookie("personal.nonce"))
  var private_key = sodium.from_base64(localStorage["personal.private"])
  var server_pub = sodium.from_base64(getCookie("personal.server_pub"))
  return sodium.to_base64(sodium.crypto_box_easy(content, nonce, server_pub, private_key))
}
function openBoxFromBase64(base64_content) {
  var nonce = sodium.from_base64(getCookie("personal.nonce"))
  var private_key = sodium.from_base64(localStorage["personal.private"])
  var server_pub = sodium.from_base64(getCookie("personal.server_pub"))
  return sodium.crypto_box_open_easy(sodium.from_base64(base64_content), nonce, server_pub, private_key)
}