
#
#  This file is part of the "Teapot" project, and is released under the MIT license.
#

teapot_version "1.0.0"

define_target "build-darwin" do |target|
	target.provides :linker => "Build/darwin"
	
	target.provides "Build/darwin" do
		define Rule, "link.darwin-static-library" do
			input :object_files, pattern: /\.o/, multiple: true
			
			output :library_file, pattern: /\.a/
			
			apply do |parameters|
				input_root = parameters[:library_file].root
				object_files = parameters[:object_files].collect{|path| path.shortest_path(input_root)}
				
				run!(
					environment[:libtool] || "libtool", 
					"-static",
					"-o", parameters[:library_file].relative_path,
					"-c", *object_files,
					chdir: input_root
				)
			end
		end
		
		define Rule, "link.darwin-executable" do
			input :object_files, pattern: /\.o$/, multiple: true
			
			parameter :library_path, optional: true do |path, arguments|
				arguments[:library_path] = path || (environment[:install_prefix] + "lib")
			end
			
			input :dependencies, implicit: true do |arguments|
				# Extract include directories:
				libraries = environment[:ldflags].select{|option| option.kind_of? Files::Path}
			end
			
			output :executable_file
			
			apply do |parameters|
				input_root = parameters[:executable_file].root
				object_files = parameters[:object_files].collect{|path| path.shortest_path(input_root)}
				
				run!(
					"clang++",
					"-o", parameters[:executable_file].relative_path,
					*object_files,
					*environment[:ldflags],
					"-L" + parameters[:library_path].shortest_path(input_root),
					chdir: input_root
				)
			end
		end
		
		define Rule, "build.static-library" do
			input :source_files
			
			parameter :prefix, optional: true do |path, arguments|
				arguments[:prefix] = path || (environment[:install_prefix] + "lib")
			end
			
			parameter :static_library
			
			output :library_file, implicit: true do |arguments|
				arguments[:prefix] / "lib#{arguments[:static_library]}.a"
			end
			
			apply do |parameters|
				# Make sure the output directory exists:
				fs.mkpath File.dirname(parameters[:library_file])
				
				build source_files: parameters[:source_files], library_file: parameters[:library_file]
			end
		end
		
		define Rule, "build.executable" do
			input :source_files
			
			parameter :prefix, optional: true do |path, arguments|
				arguments[:prefix] = path || (environment[:install_prefix] + "bin")
			end
			
			parameter :executable
			
			output :executable_file, implicit: true do |arguments|
				arguments[:prefix] / arguments[:executable]
			end
			
			apply do |parameters|
				# Make sure the output directory exists:
				fs.mkpath File.dirname(parameters[:executable_file])
				
				build source_files: parameters[:source_files], executable_file: parameters[:executable_file]
			end
		end
		
		define Rule, "run.executable" do
			parameter :executable
			
			parameter :prefix, optional: true do |path, arguments|
				arguments[:prefix] = path || (environment[:install_prefix] + "bin")
			end
			
			input :executable_file, implicit: true do |arguments|
				arguments[:prefix] / arguments[:executable]
			end
			
			parameter :args, optional: true
			
			apply do |parameters|
				run!(
					parameters[:executable_file],
					*parameters[:arguments]
				)
			end
		end
	end
end
