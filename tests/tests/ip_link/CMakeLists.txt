include("../../../SoCMakeConfig.cmake")

cmake_minimum_required(VERSION 3.0)
project(big_graph NONE)

set(TOTAL_IPS 1000)
set(BRANCHING_FACTOR 2)

# Keep track of all IPs created
set(ip_index 0)

# Add root IP
set(root_ip "ip${ip_index}")
add_ip(${root_ip})
math(EXPR ip_index "${ip_index} + 1")

# This queue will track which IPs need children
set(queue ${root_ip})

# Keep building until we reach TOTAL_IPS
while(ip_index LESS TOTAL_IPS)
    # Store next generation of IPs
    set(next_queue "")

    foreach(parent_ip IN LISTS queue)
        # If we've already created enough, stop
        if(ip_index GREATER_EQUAL TOTAL_IPS)
            break()
        endif()

        set(children "")
        foreach(i RANGE 1 ${BRANCHING_FACTOR})
            if(ip_index GREATER_EQUAL TOTAL_IPS)
                break()
            endif()

            set(child_ip "ip${ip_index}")
            add_ip(${child_ip})
            list(APPEND children ${child_ip})
            list(APPEND next_queue ${child_ip})
            math(EXPR ip_index "${ip_index} + 1")
        endforeach()

        if(children)
            ip_link(${parent_ip} ${children})
        endif()
    endforeach()

    set(queue ${next_queue})
endwhile()

