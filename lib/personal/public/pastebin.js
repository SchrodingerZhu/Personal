function openSubmit() {
    var json = {
        request: "open_submit",
        id: paste_id,
        name: paste_name,
        new_content: document.getElementById("text").value
    }  
    $.post(
        "/pastebin-api",
        JSON.stringify(json),
        function () {
            window.location.reload()
        }
    )
}
function boxedSubmit() {
    var json = {
        request: "boxed_submit",
        id: paste_id,
        name: paste_name,
        boxed_new_content: makeBoxBase64(document.getElementById("text").value)
    }
    $.post(
        "/pastebin-api",
        JSON.stringify(json),
        function () {
            window.location.reload()
        }
    )
}
