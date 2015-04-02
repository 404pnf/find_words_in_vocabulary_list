# # 目的
# 分析句子文件中的句子，找出那些在单词文件中出现的单词，并加到该条记录的最后一列

# # 使用方法
#     ruby script.rb 单词文件.csv 句子文件.csv
# 结果会是当前目录下的result.csv文件。
# 结果文件的第一列式原句子文件中的主题词，按字母排序了。
# 结果文件的第二列是在单词表出现的主题词，按字母排序了。
# 将结果复制粘贴回句子文件即可。

# # 数据接结构
# 根据观察，这个其实是个集合求交集。第一个集合是单词表文件的单词。
# 第二个集合是句子文件中每个主题对应的单词表。
# 我们需要的是第二个集合和第一个集合的交集。
# 集合交集
# set1.intersect(set2)
# set1 & set2 也可以

require 'csv'
require 'set'
require 'pp'

# ## 收集单词表单词
# 单词表文件的格式
# >> require 'csv'
# => true
# >> CSV.table("NCS-2和赵老师CCFR-1共有的词.csv")
# => #<CSV::Table mode:col_or_row row_count:120>
# >> voc.to_a
# => [[:word, :freq, :dic], ["afternoon", nil, "ZhaoCCFR-1"], ["ask", nil, "ZhaoCCFR-1"], 。。。
# 可以看出，第一个元素是csv header，从第二个开始，是内容，单词是数组的第一个元素。就取它呗。

# voc.to_a.drop(1).map(&:first).map(&:downcase)

# 搞定了。
voc_file, sents_file = ARGV
voc = CSV.table(voc_file).to_a.drop(1).map(&:first).map(&:downcase).map(&:downcase).to_set
# pp voc
# ## 主题词此表格式
# # 注意事项
# 先将单词全部转为小写，排除大小写干扰。
# 主题单词表中对处理有干扰的特殊字符
# 1、 有英文括号
# CD, guitar, kinds of music (e.g. classical, pop)
# names of musical instruments (e.g. guitar,  piano, violin)

# 这个解决比较简单，替换为英文逗号即可。
# => s = "CD, guitar, kinds of music ,e.g. classical, pop)"
# >> s.gsub(/[()]/, ',')
# => "CD, guitar, kinds of music ,e.g. classical, pop,"

# 2、 当用英文逗号split文本获得单词数组时，有些短语并没有被分成单词，
# 如上例中的 kinds of music 会作为数组元素出现。它应该是3个单词才对。
# 剞劂方法是也比较简单，在split时，用英文逗号或者空白分割即可。

# >> "CD, guitar, kinds of music (e.g. classical, pop)".split(/,| /)
# => ["CD", "", "guitar", "", "kinds", "of", "music", "(e.g.", "classical", "", "pop)"]

# 连在一起
# >> s.gsub(/[()]/, ',').split(/,| /)
# => ["CD", "", "guitar", "", "kinds", "of", "music", "", "e.g.", "classical", "", "pop"]

# 将数组转为集合
# set = s.to_set

# 将空字符串从集合中删除。delete操作直接修改了集合
# set.delete('')

# 完整的句子文件
# 使用CSV.table读入会报错。因为header那行不是所有列都有header
# 因此我们就将header作为普通记录就好了
sents = CSV.table(sents_file, headers: false)
# 只保留主题词部分
words = sents.map { |e| e[3] }

# string -> array
def make_word_list(str)
  return nil if str.nil?
  str.strip # 去掉 \n
    .gsub(/[();]/, ',')  # \去掉括号
    .split(/,| /) # 逗号或者空格分开
end

# nil.to_set 会报错 Set.new(nil) 创建空集合
# 删除集合中的空字符串
t = words.map do |e|
  ee = make_word_list(e)
  Set.new(ee).delete('')
end
# pp set
# 求交集，并把交集追加到数组的最后一列
new_sents = t.map do |e|
  intersect = e.intersection(voc)
  [e, intersect].map(&:to_a)
  .map(&:sort)
  .tap  { |ee|  ee }
  .map { |ee| ee.join(' ') }
end

CSV.open('result.csv', 'w', force_quotes: true) do |row|
  new_sents.each { |i| row << i }
end
