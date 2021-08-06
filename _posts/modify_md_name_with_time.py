import os

fileStartDate = "2021-01-01"

def update_md_file_name():
    docs_list=[]
    for path, subdirs, files in os.walk("."):
        for name in files:
            if len(name.split(".")) == 2 and name.split(".")[1] == "md":
                newName = fileStartDate + "-" + name
                print("old name is{name}, new name is{newName}".format(name=name,newName=newName))
                os.rename(name, newName)
                #docs_list.append(os.path.join(path, name))
update_md_file_name()