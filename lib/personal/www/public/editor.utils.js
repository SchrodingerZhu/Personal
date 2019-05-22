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