function! ClassGetter(class_name) dict
    let class_name = a:class_name
    if !has_key(self["class"]["prv_repo"], class_name)
        echo "\n"
        throw "Class Name Not Found"
    endif
    return self['class']['prv_repo'][class_name]['lines']
endfunction

function! TmpClassGetter(class_name, is_volatile) dict
    let class_name = a:class_name
    if !has_key(self["class"]["prv_repo"], class_name)
        echo "\n"
        throw "Class Name Not Found"
    endif
    let line_numbers = self['class']['prv_repo']['tmp'][selector_str]['lines']

    return self["prv_repo"][class_name]["lines"]
endfunction

function! ClassSetter(class_name, class_lines) dict
    if has_key(self['class']['prv_repo'], a:class_name)
        echo "\n"
        throw "Class Name already exists"
    endif
    let self['class']['prv_repo'][a:class_name] = a:class_lines
endfunction

function! TmpClassSetter(tmp_class_name, tmp_class_lines, is_volatile) dict
    "*- is_tmp: 0=normal class, 1=tmp class, 2=tmp volatile class -*
    if is_tmp == 0
        let self['class']['prv_repo']['tmp'][tmp_class_name] = tmp_class_lines
    elseif is_tmp == 1
        let self['class']['prv_repo']['tmp']['volatile'][tmp_class_name] = tmp_class_lines
    endif
endfunction

function! SetNewTmpClass(is_volatile) dict
    let new_tmp_class_name = ""
    if a:is_volatile
        let new_tmp_class_name = new_tmp_class_name . (len(keys(self['class']['prv_repo']['tmp']['volatile'])) + 1)
        let self['class']['prv_repo']['tmp']['volatile'][new_tmp_class_name]
    else
        let new_tmp_class_name = new_tmp_class_name . (len(keys(self['class']['prv_repo']['tmp'])) + 1)
        let self['class']['prv_repo']['tmp'][new_tmp_class_name]
    endif
    return new_tmp_class_name
endfunction

function! ClassNameCheck(class_name)
    let class_name = a:class_name
    if !has_key(self["class"]["prv_repo"], class_name)
        echo "\n"
        throw "Class Name (" . class_name . ") not exists"
    endif
endfunction

let doc = {
\   "class": {
\       "prv_repo": {
\           "sample": {
\               "def": "",
\               "lines": []
\           },
\           "tmp": {
\           }
\       }
\   }
\}

let [doc["pub_class_setter"], doc["pub_class_getter"], doc["pub_tmp_class_setter"], doc["pub_tmp_class_getter"]] = [
\    function("ClassSetter"), function("ClassGetter"), function("TmpClassSetter"), function("TmpClassGetter")
\]

let [doc["pub_class_name_check"]] = [
\    function("ClassNameCheck")
\]

let [doc["pub_set_new_tmp_class"]] = [
\    function("SetNewTmpClass")
\]

let [doc["pub_create_tmp_folder"], doc["pub_remove_tmp_folder"] = [
\    function("CreateTmpFolder"), function("RemoveTmpFolder")
\]

let [doc["pub_is_exists_class_name"], doc["pub_assign_tmp_class_name"], doc["pub_class_name_setter"]] = [
\    function("IsExistsClassName"), function("AssignTmpClassName"), function("Select"), function("Edit")
\]
