function allLanguages() {
    return monaco.languages.getLanguages().map(function (x) {return x.id})
}
function genSelections(){
    var select = document.getElementById('language-select');
    var opts = allLanguages();
    for (var i = 0; i < opts.length; i++){
        var opt = document.createElement('option');
        opt.value = opts[i];
        opt.innerHTML = opts[i];
        select.appendChild(opt);
    }
}

function changeLanguage(lang) {
    require(['vs/editor/editor.main'], function() {
        var model = monaco.editor.getModel("inmemory://model/1");
        monaco.editor.setModelLanguage(model, lang);
    });
}

function languageOnChange() {
    var select = document.getElementById('language-select');
    changeLanguage(select.selectedOptions[0].value);
}

function submitPaste() {
    var level = 0;
    var temp = document.getElementById("level").value;
    if (temp == "private paste") {
        level = 1;
    } else if (temp == "password paste") {
        level = 2;
    }
    var obj = {
        "title" : document.getElementById("title").value,
        "editable": document.getElementById("editable").checked,
        "level": level,
        "password": document.getElementById("password").value,
        "expire": Number(document.getElementById("expire").value),
        "content": monaco.editor.getModel("inmemory://model/1").getValue(),
        "language": document.getElementById("language-select").value
    };
    $.post(
        "/paste/new",
        makeBoxBase64(JSON.stringify(obj)),
        function (data) {
            console.log(data)
        }, "text"
    )
}