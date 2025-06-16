import sys
from collections import defaultdict

class CMakeGraphFlattener:
    def __init__(self):
        self.targets = {}
        self.global_stack = []
        self.rm_lists = defaultdict(list)
        
    def add_target(self, name, interface_link_libraries=None):
        """Simulate add_library/add_executable"""
        if interface_link_libraries is None:
            interface_link_libraries = []
        self.targets[name] = {
            'interface_link_libraries': interface_link_libraries,
            'is_target': True
        }
    
    def flatten_graph(self, node):
        """Main entry point - flatten the dependency graph starting from node"""
        node = self.alias_dereference(node)
        self.global_stack = []
        found_root = -1
        
        while found_root == -1:
            self.__flatten_graph_recursive(node)
            try:
                found_root = self.global_stack.index(node)
            except ValueError:
                found_root = -1
        
        # Clear RM lists
        for lib in self.global_stack:
            lib = self.alias_dereference(lib)
            self.rm_lists[lib] = []
            
        return self.global_stack
    
    def __flatten_graph_recursive(self, node):
        """Recursive helper for flattening"""
        node = self.alias_dereference(node)
        
        # If it's not a target (like -pthread)
        if node not in self.targets or not self.targets[node]['is_target']:
            return 1
        
        # If all dependencies have been processed
        if self.__all_vertices_removed(node):
            if node not in self.global_stack:
                self.global_stack.append(node)
            return 1
        
        # Get dependencies, filtering out special patterns
        deps = self.targets[node]['interface_link_libraries']
        deps = [d for d in deps if not d.endswith("::@")]
        
        for lib in deps:
            lib_added = self.__flatten_graph_recursive(lib)
            if lib_added == 1:
                self.__append_rm_list_unique(node, lib)
        
        return 0
    
    def __append_rm_list_unique(self, node, rm_el):
        """Add to removal list if not already present"""
        node = self.alias_dereference(node)
        if rm_el not in self.rm_lists[node]:
            self.rm_lists[node].append(rm_el)
    
    def __all_vertices_removed(self, node):
        """Check if all dependencies have been processed"""
        if node not in self.targets:
            raise ValueError(f"Node is not defined {node}")
        
        rm_list = self.rm_lists.get(node, [])
        link_libs = self.targets[node]['interface_link_libraries']
        link_libs = [lib for lib in link_libs if not lib.endswith("::@")]
        link_libs = list(dict.fromkeys(link_libs))  # Remove duplicates
        
        return self.compare_lists(rm_list, link_libs)
    
    def compare_lists(self, l1, l2):
        """Compare if two lists contain the same elements"""
        if len(l1) != len(l2):
            return False
        return all(item in l2 for item in l1)
    
    def alias_dereference(self, node):
        """Simulate CMake's alias dereferencing"""
        # In a real implementation, this would resolve CMake aliases
        return node


def test_big_graph():
    """Test with a large graph similar to the CMake test case"""
    flattener = CMakeGraphFlattener()
    total_ips = 100000
    branching_factor = 2
    
    # Add root IP
    root_ip = "ip0"
    flattener.add_target(root_ip)
    ip_index = 1
    
    queue = [root_ip]
    
    # Build the graph
    while ip_index < total_ips:
        next_queue = []
        
        for parent_ip in queue:
            if ip_index >= total_ips:
                break
            
            children = []
            for _ in range(branching_factor):
                if ip_index >= total_ips:
                    break
                
                child_ip = f"ip{ip_index}"
                flattener.add_target(child_ip)
                children.append(child_ip)
                next_queue.append(child_ip)
                ip_index += 1
            
            if children:
                # Add dependencies
                flattener.targets[parent_ip]['interface_link_libraries'].extend(children)
        
        queue = next_queue
    
    # Flatten the graph
    flattened = flattener.flatten_graph(root_ip)
    
    # print(f"Flattened graph has {len(flattened)} nodes")
    # print("First 5:", flattened[:5])
    # print("Last 5:", flattened[-5:])
    #
    # # Verify we got all nodes
    # assert len(flattened) == total_ips
    # print("Test passed!")
    #
    # for i in flattened:
    #     print(i, end=";")
    #


if __name__ == "__main__":
    test_big_graph()
