import tfcoreml as tf_converter
import json
import sys
import os


def convert():
    if len(sys.argv) < 2:
      print sys.argv[0]+' <model path>'
      return
    path = sys.argv[1]
    metadata=os.path.join(path, "metadata.json")
    graphname=os.path.join(path, "graph.pb")
    modeloutputname=os.path.join(path, "model.mlmodel")
    labelfile=os.path.join(path, "labels.txt")
    data = json.load(open(metadata))
    output_name = data['model']['output']['name']+':0'
    input_name = data['model']['input']['name']+':0'
    input_shape = data['model']['input']['shape']
    print(data)
    tf_converter.convert(tf_model_path=graphname,mlmodel_path=modeloutputname, output_feature_names=[output_name],image_input_names=input_name,input_name_shape_dict={input_name : input_shape },class_labels=labelfile)

if __name__ == "__main__":
    convert()
