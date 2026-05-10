
source_file = 'project_context_snapshot.dart'
lines = File.readlines(source_file)
total_lines = lines.length
lines_per_part = (total_lines.to_f / 10).ceil

(1..10).each do |i|
  start_index = (i - 1) * lines_per_part
  end_index = [i * lines_per_part - 1, total_lines - 1].min
  
  part_file = "project_snapshot_part_#{i}.dart"
  File.open(part_file, 'w') do |f|
    f.puts "// PART #{i} OF 10"
    f.puts "// SOURCE: project_context_snapshot.dart"
    f.puts lines[start_index..end_index]
  end
end
