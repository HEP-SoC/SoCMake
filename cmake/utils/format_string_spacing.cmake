include_guard(GLOBAL)

# Take an input list of strings with single space words and replace each
# space with the corresponding formatting character (e.g., tab(s), space(s)).
# If a space is not given a replacement character, a single space is kept
#
# Example usage:
# set(input_list " test1: Test1 does that." " test2: Test2 does this and that.")
# set(replacements "   ;\t")
#
# format_string(FORMATTED_STRING "${input_list}" "${replacements}")
# Output:
#    test1:   Test1 does that.
#    test2:   Test2 does this and that.

function(format_string_spacing OUTPUT_VAR input_list replacements)
    # Split the replacement characters into a list.
    string(REPLACE ";" ";" replacement_list "${replacements}")

    set(formatted_string "")   # To store the final formatted result
    set(max_lengths "")        # To store the maximum length of each part before spaces


    # Step 1: Calculate maximum lengths for the sections before each space
    foreach(line IN LISTS input_list)
        string(REPLACE " " ";" split_line "${line}")
        set(index 0)
        foreach(section IN LISTS split_line)
            string(LENGTH "${section}" section_length)

            # Expand max_lengths if it is the first pass
            list(LENGTH max_lengths list_size)
            if(list_size LESS_EQUAL index)
                list(APPEND max_lengths 0)
            endif()

            # Update max length for each column section
            list(GET max_lengths ${index} current_max_length)
            if(section_length GREATER current_max_length)
                list(REMOVE_AT max_lengths ${index})
                list(INSERT max_lengths ${index} ${section_length})
            endif()

            math(EXPR index "${index} + 1")
        endforeach()
    endforeach()

    # Step 2: Format each line based on the calculated max lengths
    foreach(line IN LISTS input_list)
        string(REPLACE " " ";" split_line "${line}")

        set(formatted_line "")
        set(index 0)
        foreach(section IN LISTS split_line)
            # Get the length of the section
            string(LENGTH "${section}" section_length)

            # Get the max length for this section
            list(GET max_lengths ${index} max_length)

            # Pad the section with spaces to match the maximum length
            math(EXPR padding_length "${max_length} - ${section_length}")
            string(REPEAT " " ${padding_length} padding)

            # Append the section to the formatted line
            set(formatted_line "${formatted_line}${section}")

            # Add the replacement string if available, otherwise keep original space
            list(LENGTH replacement_list replacement_count)
            if(${index} LESS replacement_count)
                list(GET replacement_list ${index} replacement_char)
                set(formatted_line "${formatted_line}${padding}${replacement_char}")
            else()
                # Add original space back if no replacement is available
                set(formatted_line "${formatted_line} ")
            endif()

            math(EXPR index "${index} + 1")
        endforeach()

        # Add the formatted line to the final formatted string
        string(APPEND formatted_string "${formatted_line}\n")
    endforeach()

    # Step 3: Return the formatted string
    set(${OUTPUT_VAR} "${formatted_string}" PARENT_SCOPE)
endfunction()
