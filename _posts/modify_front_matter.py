import os,re,codecs

def get_docs_list():
    docs_list=[]
    for path, subdirs, files in os.walk("."):
        for name in files:
            if len(name.split(".")) == 2 and name.split(".")[1] == "md":
                docs_list.append(os.path.join(path, name))
    return docs_list

def get_doc_title(file):
    with open(file,"r+", encoding="utf-8") as f:
        content = f.readlines()
        for line in content:
            if re.fullmatch("#+ .*\n", line):
                titleRegex = re.compile(r"#+ (.*)\n")
                title = titleRegex.search(line).group(1)
                return title

def remove_front_matter(file):
    with codecs.open(file, "r+", encoding="utf-8") as f:
        content = f.read()
        #print(content)
        # 使用正则匹配由---所包含的区域，然后使用re.sub进行替换，将搜索到的内容都替换为空。中文字符在UTF-8的编码下，正则为 \u4e00-\u9fa5
        reg = re.compile("---\r\n[\sa-zA-Z:\u4e00-\u9fa50-9\-\+]*---")        
        subcontent = re.sub(reg, "", content)
        print(subcontent)
        f.seek(0)
        f.write(subcontent)

def add_front_matter(file):
    with open(file,"r+", encoding="utf-8") as f:
        content = f.read()
        title = get_doc_title(file)
        f.seek(0)
        f.write("---\nauthor: liualexiang\ntitle: {title}\nlayout: post\ndate: 2021-01-01 00:00:00 +0800\n---\n".format(title= title) + content)


def do_add_front_matter(file):
    with open(file,"r+", encoding="utf-8") as f:
        first_line = f.readlines()[0]
        if re.match("-+", first_line):
            pass
        else:
            add_front_matter(file)

def traversal_remove_front_matter():
    docs_list = get_docs_list()
    for doc in docs_list:
        remove_front_matter(doc)

def traversal_add_front_matter():
    docs_list = get_docs_list()
    for doc in docs_list:
        print(doc)
        do_add_front_matter(doc)

# if __name__ == "__main__":
#     traversal_remove_front_matter()

if __name__ == "__main__":
    traversal_add_front_matter()