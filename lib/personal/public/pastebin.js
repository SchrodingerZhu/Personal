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