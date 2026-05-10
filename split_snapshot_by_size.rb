
source_file = 'project_context_snapshot.dart'
total_size = File.size(source_file)
target_size = (total_size.to_f / 10).ceil

File.open(source_file, 'rb') do |input|
  (1..10).each do |i|
    part_file = "project_snapshot_part_#{i}.dart"
    header = "// PART #{i} OF 10\n// SOURCE: project_context_snapshot.dart\n"
    
    File.open(part_file, 'wb') do |output|
      output.write(header)
      
      if i == 10
        output.write(input.read)
      else
        chunk = input.read(target_size)
        # Try to finish the current line to preserve boundaries
        remainder = input.gets
        output.write(chunk)
        output.write(remainder) if remainder
      end
    end
  end
end
