function! PrintClass() dict
    let class_name = input("Printing Class. Which Class do you want to print? (enter 'all' to print all)\n")
    if class_name == "all"
        let tab_content = []
        let delimiter = repeat("-", 30)
        let all_class_names = get_all_class_names()
        for current_class_name in keys(self["prv_repo"])
            let class_header = "Class Name: " . current_class_name
            let class_def = "Definition: " . self["prv_repo"][current_class_name]
            let class_lines = "No. of lines: " . len(self["prv_repo"][current_class_name]["lines"])
            let class_content = join([class_header, class_def, class_lines, delimiter], "\n")
            add(tab_content, class_content)
        endfor
        let tab_content_str = join(tab_content, "\n")

        tabnew
        put=tab_content_str
    elseif exists_class_name()
        let class_header = "Class Name: " . current_class_name
        let class_def = "Definition: " . self["prv_repo"][current_class_name]
        let class_lines = "No. of lines: " . len(self["prv_repo"][current_class_name]["lines"])
        let class_content = join([class_header, class_def, class_lines, delimiter], "\n")

        tabnew
        put=class_content
    else
        echo "\n"
        throw "Class Not Found"
    endif
endfunction

function! ClearClass() dict
    let class_name = input("Clearing Class. Which Class do you want to clear? (enter 'all' to clear all)\n")
    if exists_class_name()
        clear_class()
    else
        echo "\n"
        throw "Class Not Found"
    endif
endfunction

function! DefineClass() dict
    let class_name = input("Defining Class. Please enter Class Name.\n")
    if class_name =~ '^\s*$'
        echo "\n"
        throw "Class Name is empty"
    endif
    if class_name =~ '^\d'
        echo "\n"
        throw "Class Name cannot start with a number"
    endif

    let class_def = input("Please enter RegExp for this Class:-\n)
    regexp_checking(class_def)

    try
        let class_def_cmd = "g`" . class_def . "`"
        execute class_def_cmd
    catch
        echo "\n"
        throw "Invalid Pattern Format"
    endtry

    let class_lines = []
    for line_number in range(1, line('$'))
        if getline(line_number) =~ class_def
            call add(class_lines, line_number)
        endif
    endfor

    if len(class_lines) == 0 
        echo "\n"
        throw "This Class Definition has 0 Matches"
    endif

    let self['class']['prv_repo'][class_name] = {}
    let self['class']['prv_repo'][class_name]['def'] = class_def
    let self['class']['prv_repo'][class_name]['lines'] = class_lines

endfunction

function! Select() dict
    let selector = input("Please enter selector.\n")
    let selector = substitute(selector, '\s\+', '', 'g')
    call selector_help_obj["unbalanced_brackets_check"](selector)
    call selector_help_obj["adjacent_group_check"](selector)
    call selector_help_obj["selector_class_name_check"](selector)

    while selector !=~ '^\w\+$'
        let selector = selector->selector_help_obj["debracket_lone_groups"]()->selector_help_obj["process_exp"]()
    endwhile
    let class_name = selector

    let lines = []
    let line_nos = []
    if has_key(self["class"]["prv_repo"], class_name)
        let line_nos = self["class"]["prv_repo"][class_name]["lines"]
    elseif has_key(self["class"]["prv_repo"]["tmp"], class_name)
        let line_nos = self["class"]["prv_repo"]["tmp"][class_name]["lines"]
    endif
    
    for line_no in line_nos
        call add(lines, getline(line_no))
    endfor
    let lines_content = join(lines, "\n")
    
    tabnew
    put=lines_content
endfunction

function! Edit() dict
endfunction

function! ActiveFile() dict
endfunction

function! InitFile() dict
endfunction