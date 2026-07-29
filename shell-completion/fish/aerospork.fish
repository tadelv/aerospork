function _aerospork_47
    set 1 $argv[1]
    aerospork list-workspaces --monitor all --empty no
end

function _aerospork_50
    set 1 $argv[1]
    aerospork config --get mode --keys
end

function _aerospork_43
    set 1 $argv[1]
    aerospork list-windows --all --format '%{window-id}%{tab}%{app-name} - %{window-title}'
end

function _aerospork_54
    set 1 $argv[1]
    true
end

function _aerospork_38
    set 1 $argv[1]
    aerospork list-apps --format '%{app-bundle-id}%{tab}%{app-name}'
end

function _aerospork_55
    set 1 $argv[1]
    aerospork list-apps --format '%{app-pid}%{tab}%{app-name}'
end

function _aerospork_52
    set 1 $argv[1]
    aerospork list-monitors --format '%{monitor-id}%{tab}%{monitor-name}'
end

function _aerospork_22
    set 1 $argv[1]
    aerospork config --get mode --keys | xargs -I{} aerospork config --get mode.{}.binding --keys
end

function _aerospork_13
    set 1 $argv[1]
    aerospork config --major-keys
end

function _aerospork_subword_cmd_0
    true
end

function _aerospork_subword_1
    set mode $argv[1]
    set word $argv[2]

    set --local literals "-" "+"

    set --local descriptions

    set --local literal_transitions
    set literal_transitions[1] "set inputs 1 2; set tos 2 2"

    set --local match_anything_transitions_from 1 2
    set --local match_anything_transitions_to 3 3

    set --local state 1
    set --local char_index 1
    set --local matched 0
    while true
        if test $char_index -gt (string length -- "$word")
            set matched 1
            break
        end

        set --local subword (string sub --start=$char_index -- "$word")

        if set --query literal_transitions[$state] && test -n $literal_transitions[$state]
            set --local --erase inputs
            set --local --erase tos
            eval $literal_transitions[$state]

            set --local literal_matched 0
            for literal_id in (seq 1 (count $literals))
                set --local literal $literals[$literal_id]
                set --local literal_len (string length -- "$literal")
                set --local subword_slice (string sub --end=$literal_len -- "$subword")
                if test $subword_slice = $literal
                    set --local index (contains --index -- $literal_id $inputs)
                    set state $tos[$index]
                    set char_index (math $char_index + $literal_len)
                    set literal_matched 1
                    break
                end
            end
            if test $literal_matched -ne 0
                continue
            end
        end

        if set --query match_anything_transitions_from[$state] && test -n $match_anything_transitions_from[$state]
            set --local index (contains --index -- $state $match_anything_transitions_from)
            set state $match_anything_transitions_to[$index]
            set --local matched 1
            break
        end

        break
    end

    if test $mode = matches
        return (math 1 - $matched)
    end


    set --local unmatched_suffix (string sub --start=$char_index -- $word)

    set --local matched_prefix
    if test $char_index -eq 1
        set matched_prefix ""
    else
        set matched_prefix (string sub --end=(math $char_index - 1) -- "$word")
    end
    if set --query literal_transitions[$state] && test -n $literal_transitions[$state]
        set --local --erase inputs
        set --local --erase tos
        eval $literal_transitions[$state]
        for literal_id in $inputs
            set --local unmatched_suffix_len (string length -- $unmatched_suffix)
            if test $unmatched_suffix_len -gt 0
                set --local literal $literals[$literal_id]
                set --local slice (string sub --end=$unmatched_suffix_len -- $literal)
                if test "$slice" != "$unmatched_suffix"
                    continue
                end
            end
            if test -n $descriptions[$literal_id]
                printf '%s%s\t%s\n' $matched_prefix $literals[$literal_id] $descriptions[$literal_id]
            else
                printf '%s%s\n' $matched_prefix $literals[$literal_id]
            end
        end
    end

    set command_states 1 2
    set command_ids 0 0
    if contains $state $command_states
        set --local index (contains --index $state $command_states)
        set --local function_id $command_ids[$index]
        set --local function_name _aerospork_subword_cmd_$function_id
        set --local --erase inputs
        set --local --erase tos
        $function_name "$matched_prefix" | while read --local line
            printf '%s%s\n' $matched_prefix $line
        end
    end

    return 0
end


function _aerospork
    set COMP_LINE (commandline --cut-at-cursor)

    set COMP_WORDS
    echo $COMP_LINE | read --tokenize --array COMP_WORDS
    if string match --quiet --regex '.*\s$' $COMP_LINE
        set COMP_CWORD (math (count $COMP_WORDS) + 1)
    else
        set COMP_CWORD (count $COMP_WORDS)
    end

    set --local literals "move-mouse" "--count" "-v" "smart" "macos-native-fullscreen" "mute-toggle" "height" "toggle" "all-monitors-outer-frame" "h_accordion" "all" "--window-id" "monitor-force-center" "list-apps" "flatten-workspace-tree" "mode" "width" "summon-workspace" "focus-back-and-forth" "list-monitors" "h_tiles" "prev" "window-force-center" "trigger-binding" "-h" "move-node-to-workspace" "wrap-around-the-workspace" "enable" "--ignore-floating" "--visible" "close-all-windows-but-current" "--help" "--macos-native-hidden" "off" "move-workspace-to-monitor" "--boundaries" "set" "workspace-back-and-forth" "--quit-if-last-window" "window-lazy-center" "workspace" "--major-keys" "accordion" "--focused" "tiling" "--app-bundle-id" "--mouse" "balance-sizes" "opposite" "on" "--auto-back-and-forth" "--version" "--json" "join-with" "reload-config" "--workspace" "floating" "--mode" "--boundaries-action" "resize" "visible" "close" "up" "layout" "--fail-if-noop" "list-exec-env-vars" "fail" "--monitor" "--focus-follows-window" "split" "--pid" "mute-on" "v_tiles" "monitor-lazy-center" "--keys" "wrap-around-all-monitors" "--wrap-around" "horizontal" "create-implicit-container" "config" "--no-outer-gaps" "focused" "mute-off" "--all-keys" "--show-secrets" "--all" "left" "right" "--config-path" "--get" "--empty" "tiles" "--no-gui" "--format" "smart-opposite" "list-modes" "--dry-run" "move-node-to-monitor" "move" "focus" "down" "list-workspaces" "volume" "no" "stop" "debug-windows" "macos-native-minimize" "list-windows" "mouse" "next" "--dfs-index" "open-settings" "fullscreen" "focus-monitor" "--current" "v_accordion" "vertical"

    set --local descriptions

    set --local literal_transitions
    set literal_transitions[1] "set inputs 1 3 54 55 35 5 38 60 62 96 14 41 64 66 15 98 70 20 16 19 99 100 18 24 25 102 26 103 106 107 108 28 48 80 112 31 52 113 32 114; set tos 107 3 112 113 50 63 3 85 67 105 82 98 114 115 4 102 8 59 52 3 7 71 109 56 3 116 117 90 9 9 16 118 4 77 3 79 3 119 3 80"
    set literal_transitions[2] "set inputs 77; set tos 3"
    set literal_transitions[4] "set inputs 56; set tos 5"
    set literal_transitions[6] "set inputs 67 79 105; set tos 7 7 7"
    set literal_transitions[7] "set inputs 36 59 87 88 12 101 63; set tos 91 6 89 89 92 89 89"
    set literal_transitions[8] "set inputs 49 12 78 117; set tos 9 10 9 9"
    set literal_transitions[9] "set inputs 12; set tos 25"
    set literal_transitions[12] "set inputs 81 65 12 34 50; set tos 32 27 33 74 34"
    set literal_transitions[13] "set inputs 56 77; set tos 14 15"
    set literal_transitions[15] "set inputs 56 77; set tos 14 15"
    set literal_transitions[16] "set inputs 71 2 56 94 44 86 46 53 68; set tos 17 18 19 20 21 21 22 18 23"
    set literal_transitions[18] "set inputs 71 2 56 94 44 86 46 53 68; set tos 17 37 19 38 21 21 22 37 23"
    set literal_transitions[19] "set inputs 61 82; set tos 124 124"
    set literal_transitions[21] "set inputs 94 2 53; set tos 73 3 3"
    set literal_transitions[23] "set inputs 11 109 82; set tos 87 87 87"
    set literal_transitions[27] "set inputs 81 65 12 50; set tos 27 27 26 34"
    set literal_transitions[28] "set inputs 53 90 75; set tos 28 29 28"
    set literal_transitions[30] "set inputs 53 75; set tos 30 30"
    set literal_transitions[31] "set inputs 10 21 57 78 92 45 73 43 116 117; set tos 31 31 31 31 31 31 31 31 31 31"
    set literal_transitions[32] "set inputs 81 65 12 50; set tos 32 27 33 34"
    set literal_transitions[34] "set inputs 12 81 65; set tos 123 34 34"
    set literal_transitions[36] "set inputs 78 117 49; set tos 9 9 9"
    set literal_transitions[37] "set inputs 71 2 46 56 53 68 94; set tos 17 37 22 19 37 23 38"
    set literal_transitions[39] "set inputs 12 65 69; set tos 40 39 39"
    set literal_transitions[42] "set inputs 65 12 77 69; set tos 42 41 42 42"
    set literal_transitions[44] "set inputs 10 21 57 78 92 45 73 43 116 117; set tos 31 31 31 31 31 31 31 31 31 31"
    set literal_transitions[45] "set inputs 105 27 67 76; set tos 46 46 46 46"
    set literal_transitions[46] "set inputs 36 59 87 88 101 29 63; set tos 72 45 48 48 48 46 48"
    set literal_transitions[47] "set inputs 9 41; set tos 48 48"
    set literal_transitions[48] "set inputs 36 59 29; set tos 47 66 48"
    set literal_transitions[50] "set inputs 110 56 22 101 63 87 88 77; set tos 15 49 15 15 15 15 15 50"
    set literal_transitions[51] "set inputs 58; set tos 52"
    set literal_transitions[53] "set inputs 30 2 104 91 94 53; set tos 53 54 54 53 55 54"
    set literal_transitions[54] "set inputs 30 2 91 94 53; set tos 53 54 53 55 54"
    set literal_transitions[56] "set inputs 58; set tos 35"
    set literal_transitions[57] "set inputs 77 69; set tos 57 57"
    set literal_transitions[58] "set inputs 104 2 94 53 47 44; set tos 59 59 60 59 58 58"
    set literal_transitions[59] "set inputs 2 94 53 47 44; set tos 59 60 59 58 58"
    set literal_transitions[62] "set inputs 17 4 7 95; set tos 76 76 76 76"
    set literal_transitions[63] "set inputs 65 12 34 50; set tos 63 64 65 65"
    set literal_transitions[65] "set inputs 12 65; set tos 93 65"
    set literal_transitions[66] "set inputs 105 27 67 76; set tos 48 48 48 48"
    set literal_transitions[67] "set inputs 12 39; set tos 68 67"
    set literal_transitions[70] "set inputs 12 65 69; set tos 69 70 70"
    set literal_transitions[71] "set inputs 12 101 29 63 36 59 87 88 111; set tos 25 48 46 48 72 45 48 48 73"
    set literal_transitions[72] "set inputs 9 41; set tos 46 46"
    set literal_transitions[74] "set inputs 12 65; set tos 25 3"
    set literal_transitions[75] "set inputs 87 88 110 101 22 63; set tos 2 2 2 2 2 2"
    set literal_transitions[77] "set inputs 84 42 75 53 90 89; set tos 3 3 28 28 29 3"
    set literal_transitions[78] "set inputs 81 65 12 34 50; set tos 27 27 26 74 34"
    set literal_transitions[79] "set inputs 39; set tos 3"
    set literal_transitions[80] "set inputs 110 101 22 63 87 88 77; set tos 2 2 2 2 2 2 75"
    set literal_transitions[82] "set inputs 2 94 53 33; set tos 82 83 82 84"
    set literal_transitions[84] "set inputs 104 2 94 53 33; set tos 82 82 83 82 84"
    set literal_transitions[85] "set inputs 17 4 7 12 95; set tos 76 76 76 61 76"
    set literal_transitions[86] "set inputs 51 65; set tos 86 86"
    set literal_transitions[87] "set inputs 11 2 71 109 56 94 68 46 53 82; set tos 87 37 17 87 19 38 23 22 37 87"
    set literal_transitions[89] "set inputs 12 36 59; set tos 88 128 120"
    set literal_transitions[90] "set inputs 63 37 6 72 101 83; set tos 3 73 3 3 3 3"
    set literal_transitions[91] "set inputs 9 41; set tos 7 7"
    set literal_transitions[95] "set inputs 65; set tos 3"
    set literal_transitions[97] "set inputs 110 12 22 101 63 87 88 65 77 69; set tos 42 96 42 42 42 42 42 97 97 97"
    set literal_transitions[98] "set inputs 51 65 110 22 77; set tos 99 99 2 2 100"
    set literal_transitions[99] "set inputs 65 51; set tos 99 99"
    set literal_transitions[100] "set inputs 22 110; set tos 2 2"
    set literal_transitions[102] "set inputs 110 12 22 101 63 87 88 65 77 69; set tos 42 101 42 42 42 42 42 102 97 102"
    set literal_transitions[103] "set inputs 110 22 77 69; set tos 57 57 103 103"
    set literal_transitions[104] "set inputs 87 88 101 63; set tos 3 3 3 3"
    set literal_transitions[105] "set inputs 115; set tos 3"
    set literal_transitions[107] "set inputs 65 40 13 23 74; set tos 108 95 95 95 95"
    set literal_transitions[108] "set inputs 74 40 13 23; set tos 95 95 95 95"
    set literal_transitions[109] "set inputs 65; set tos 94"
    set literal_transitions[111] "set inputs 2 91 94 44 30 86 53 68; set tos 122 125 121 21 125 21 122 126"
    set literal_transitions[112] "set inputs 87 88 12 101 63; set tos 3 3 106 3 3"
    set literal_transitions[113] "set inputs 93 97; set tos 113 113"
    set literal_transitions[114] "set inputs 10 92 12 21 57 78 45 73 43 116 117; set tos 31 31 43 31 31 31 31 31 31 31 31"
    set literal_transitions[115] "set inputs 85; set tos 3"
    set literal_transitions[116] "set inputs 2 91 94 44 30 86 53 68; set tos 111 125 110 21 125 21 111 126"
    set literal_transitions[117] "set inputs 65 69 110 12 77 22; set tos 70 117 57 69 103 57"
    set literal_transitions[118] "set inputs 65 34 8 50; set tos 129 95 3 95"
    set literal_transitions[119] "set inputs 81 65 12 34 50; set tos 32 78 11 74 34"
    set literal_transitions[120] "set inputs 67 79 105; set tos 89 89 89"
    set literal_transitions[122] "set inputs 30 2 91 94 53 68; set tos 125 122 125 121 122 126"
    set literal_transitions[124] "set inputs 71 2 61 56 94 46 53 82 68; set tos 17 37 124 19 38 22 37 124 23"
    set literal_transitions[125] "set inputs 30 2 104 91 94 53 68; set tos 125 122 122 125 121 122 126"
    set literal_transitions[126] "set inputs 11 109 82; set tos 130 130 130"
    set literal_transitions[127] "set inputs 65 12 69; set tos 39 40 39"
    set literal_transitions[128] "set inputs 9 41; set tos 89 89"
    set literal_transitions[129] "set inputs 34 50; set tos 95 95"
    set literal_transitions[130] "set inputs 11 2 109 91 94 30 53 82; set tos 130 54 130 53 55 53 54 130"

    set --local match_anything_transitions_from 24 40 127 96 88 99 123 80 11 106 83 5 29 43 25 10 14 60 20 101 68 56 94 33 69 38 70 64 26 55 109 50 124 61 117 126 41 22 102 92 49 52 93 130 19 81 98 121 23 35 73 87 13 110 17
    set --local match_anything_transitions_to 3 39 127 97 89 86 34 81 12 104 82 3 30 44 3 36 15 59 18 102 67 51 95 32 70 37 39 63 27 54 95 13 124 62 39 130 42 37 127 7 50 3 65 130 124 81 86 122 87 24 3 87 13 111 37
    set subword_transitions[76] "set subword_ids 1; set tos 9"

    set --local state 1
    set --local word_index 2
    while test $word_index -lt $COMP_CWORD
        set --local -- word $COMP_WORDS[$word_index]

        if set --query literal_transitions[$state] && test -n $literal_transitions[$state]
            set --local --erase inputs
            set --local --erase tos
            eval $literal_transitions[$state]

            if contains -- $word $literals
                set --local literal_matched 0
                for literal_id in (seq 1 (count $literals))
                    if test $literals[$literal_id] = $word
                        set --local index (contains --index -- $literal_id $inputs)
                        set state $tos[$index]
                        set word_index (math $word_index + 1)
                        set literal_matched 1
                        break
                    end
                end
                if test $literal_matched -ne 0
                    continue
                end
            end
        end

        if set --query subword_transitions[$state] && test -n $subword_transitions[$state]
            set --local --erase subword_ids
            set --local --erase tos
            eval $subword_transitions[$state]

            set --local subword_matched 0
            for subword_id in $subword_ids
                if _aerospork_subword_$subword_id matches "$word"
                    set subword_matched 1
                    set state $tos[$subword_id]
                    set word_index (math $word_index + 1)
                    break
                end
            end
            if test $subword_matched -ne 0
                continue
            end
        end

        if set --query match_anything_transitions_from[$state] && test -n $match_anything_transitions_from[$state]
            set --local index (contains --index -- $state $match_anything_transitions_from)
            set state $match_anything_transitions_to[$index]
            set word_index (math $word_index + 1)
            continue
        end

        return 1
    end

    if set --query literal_transitions[$state] && test -n $literal_transitions[$state]
        set --local --erase inputs
        set --local --erase tos
        eval $literal_transitions[$state]
        for literal_id in $inputs
            if test -n $descriptions[$literal_id]
                printf '%s\t%s\n' $literals[$literal_id] $descriptions[$literal_id]
            else
                printf '%s\n' $literals[$literal_id]
            end
        end
    end


    if set --query subword_transitions[$state] && test -n $subword_transitions[$state]
        set --local --erase subword_ids
        set --local --erase tos
        eval $subword_transitions[$state]

        for subword_id in $subword_ids
            set --local function_name _aerospork_subword_$subword_id
            $function_name complete "$COMP_WORDS[$COMP_CWORD]"
        end
    end

    set command_states 87 106 70 83 64 26 50 55 24 40 5 109 29 124 93 61 130 19 81 117 43 25 10 98 121 14 110 127 60 23 20 101 68 126 35 96 88 99 56 123 94 33 69 73 41 22 80 38 102 92 13 11 49 52 17
    set command_ids 52 43 47 54 43 43 54 54 22 43 47 47 13 47 43 43 52 47 54 47 43 43 43 47 54 47 54 54 54 52 54 43 43 52 50 43 43 47 22 43 47 43 43 54 43 38 54 54 54 43 54 43 47 50 55
    if contains $state $command_states
        set --local index (contains --index $state $command_states)
        set --local function_id $command_ids[$index]
        set --local function_name _aerospork_$function_id
        set --local --erase inputs
        set --local --erase tos
        $function_name "$COMP_WORDS[$COMP_CWORD]"
    end

    return 0
end

complete --command aerospork --no-files --arguments "(_aerospork)"
