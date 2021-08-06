import os,re

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


def add_front_matter(file):
    with open(file,"r+", encoding="utf-8") as f:
        content = f.read()
        title = get_doc_title(file)
        f.seek(0)
        f.write("---\nauthor: liualexiang\ntitle:{title}\n---\n\n".format(title= title) + content)


def do_add_front_matter(file):
    with open(file,"r+", encoding="utf-8") as f:
        first_line = f.readlines()[0]
        if re.match("-+", first_line):
            pass
        else:
            add_front_matter(file)

if __name__ == "__main__":
    docs_list = get_docs_list()
    for doc in docs_list:
        do_add_front_matter(doc)