#include <iostream>
#include <vector>
#include <unordered_map>
#include <unordered_set>
#include <string>
#include <algorithm>

class CMakeGraphFlattener {
public:
    struct Target {
        std::vector<std::string> interface_link_libraries;
        bool is_target = true;
    };

    void add_target(const std::string& name, 
                   const std::vector<std::string>& deps = {}) {
        targets_[name] = {deps, true};
    }

    std::vector<std::string> flatten_graph(const std::string& node) {
        std::string resolved_node = alias_dereference(node);
        global_stack_.clear();
        int found_root = -1;

        while (found_root == -1) {
            __flatten_graph_recursive(resolved_node);
            auto it = std::find(global_stack_.begin(), global_stack_.end(), resolved_node);
            found_root = (it != global_stack_.end()) ? 1 : -1;
        }

        // Clear RM lists
        for (const auto& lib : global_stack_) {
            rm_lists_[lib].clear();
        }

        return global_stack_;
    }

    int __flatten_graph_recursive(const std::string& node) {
        std::string resolved_node = alias_dereference(node);

        // If it's not a target (like -pthread)
        if (targets_.count(resolved_node) == 0 || !targets_[resolved_node].is_target) {
            return 1;
        }

        // If all dependencies have been processed
        if (__all_vertices_removed(resolved_node)) {
            if (std::find(global_stack_.begin(), global_stack_.end(), resolved_node) == global_stack_.end()) {
                global_stack_.push_back(resolved_node);
            }
            return 1;
        }

        // Get dependencies, filtering out special patterns
        auto deps = targets_[resolved_node].interface_link_libraries;
        deps.erase(std::remove_if(deps.begin(), deps.end(),
                   [](const std::string& s) { return s.find("::@") != std::string::npos; }),
                   deps.end());

        for (const auto& lib : deps) {
            int lib_added = __flatten_graph_recursive(lib);
            if (lib_added == 1) {
                __append_rm_list_unique(resolved_node, lib);
            }
        }

        return 0;
    }

    void __append_rm_list_unique(const std::string& node, const std::string& rm_el) {
        std::string resolved_node = alias_dereference(node);
        auto& rm_list = rm_lists_[resolved_node];
        if (std::find(rm_list.begin(), rm_list.end(), rm_el) == rm_list.end()) {
            rm_list.push_back(rm_el);
        }
    }

    bool __all_vertices_removed(const std::string& node) {
        if (targets_.count(node) == 0) {
            throw std::runtime_error("Node is not defined: " + node);
        }

        auto& rm_list = rm_lists_[node];
        auto link_libs = targets_[node].interface_link_libraries;

        // Filter and remove duplicates
        link_libs.erase(std::remove_if(link_libs.begin(), link_libs.end(),
                       [](const std::string& s) { return s.find("::@") != std::string::npos; }),
                       link_libs.end());
        std::sort(link_libs.begin(), link_libs.end());
        link_libs.erase(std::unique(link_libs.begin(), link_libs.end()), link_libs.end());

        return compare_lists(rm_list, link_libs);
    }

    bool compare_lists(const std::vector<std::string>& l1, 
                      const std::vector<std::string>& l2) {
        if (l1.size() != l2.size()) return false;

        auto l1_sorted = l1;
        auto l2_sorted = l2;
        std::sort(l1_sorted.begin(), l1_sorted.end());
        std::sort(l2_sorted.begin(), l2_sorted.end());

        return l1_sorted == l2_sorted;
    }

    std::string alias_dereference(const std::string& node) {
        // In a real implementation, this would resolve CMake aliases
        return node;
    }

    std::unordered_map<std::string, Target> targets_;
    std::unordered_map<std::string, std::vector<std::string>> rm_lists_;
    std::vector<std::string> global_stack_;
};

void test_big_graph() {
    CMakeGraphFlattener flattener;
    const int TOTAL_IPS = 100000;
    const int BRANCHING_FACTOR = 2;

    // Add root IP
    std::string root_ip = "ip0";
    flattener.add_target(root_ip);
    int ip_index = 1;

    std::vector<std::string> queue = {root_ip};

    // Build the graph
    while (ip_index < TOTAL_IPS) {
        std::vector<std::string> next_queue;

        for (const auto& parent_ip : queue) {
            if (ip_index >= TOTAL_IPS) break;

            std::vector<std::string> children;
            for (int i = 0; i < BRANCHING_FACTOR; i++) {
                if (ip_index >= TOTAL_IPS) break;

                std::string child_ip = "ip" + std::to_string(ip_index);
                flattener.add_target(child_ip);
                children.push_back(child_ip);
                next_queue.push_back(child_ip);
                ip_index++;
            }

            if (!children.empty()) {
                // Add dependencies
                auto& deps = flattener.targets_[parent_ip].interface_link_libraries;
                deps.insert(deps.end(), children.begin(), children.end());
            }
        }

        queue = next_queue;
    }

    // Flatten the graph
    auto flattened = flattener.flatten_graph(root_ip);

    std::cout << "Flattened graph has " << flattened.size() << " nodes\n";
    std::cout << "First 5: ";
    for (int i = 0; i < 5 && i < flattened.size(); i++) 
        std::cout << flattened[i] << " ";
    std::cout << "\nLast 5: ";
    for (int i = std::max(0, (int)flattened.size() - 5); i < flattened.size(); i++)
        std::cout << flattened[i] << " ";
    std::cout << "\n";

    // Verify we got all nodes
    if (flattened.size() == TOTAL_IPS) {
        std::cout << "Test passed!\n";
    } else {
        std::cout << "Test failed! Expected " << TOTAL_IPS 
                  << " nodes, got " << flattened.size() << "\n";
    }
}

int main() {
    test_big_graph();
    return 0;
}
