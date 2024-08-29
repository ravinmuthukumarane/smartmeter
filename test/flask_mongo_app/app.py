from flask import Flask, render_template, send_file, jsonify, redirect, url_for
from flask_pymongo import PyMongo
from io import BytesIO
import base64
import zipfile
import os
from bson import ObjectId

app = Flask(__name__)

# Configure the MongoDB connection
app.config["MONGO_URI"] = "mongodb://appUser:password@192.46.214.230:27017/smart_meter_app"

# Initialize PyMongo
mongo = PyMongo(app)

@app.route('/')
def index():
    # Fetch data from MongoDB
    meter_data = mongo.db.meter_data.find()
    
    # Render the data in a template
    return render_template('index.html',  meter_data=meter_data)

@app.route('/image/<image_id>')
def image(image_id):
    # Fetch the image document from MongoDB
    image_data = mongo.db.meter_data.find_one({'_id': ObjectId(image_id)})
    if image_data and 'image_data' in image_data:
        # Decode the Base64 image data
        image_bytes = base64.b64decode(image_data['image_data'])
        return send_file(BytesIO(image_bytes), mimetype='image/jpeg')
    return jsonify({"error": "Image not found"}), 404

@app.route('/export')
def export_data():
    # Fetch data from MongoDB
    meter_data = list(mongo.db.meter_data.find())

    # Create a ZIP file in memory
    memory_file = BytesIO()
    with zipfile.ZipFile(memory_file, 'w') as zf:

        # Add meter_data to the ZIP file
        meter_data_file = BytesIO()
        meter_data_file.write(str(meter_data).encode('utf-8'))
        zf.writestr('meter_data.json', meter_data_file.getvalue())

        # Add images to the ZIP file
        for data in meter_data:
            if 'image_data' in data:
                image_bytes = base64.b64decode(data['image_data'])
                image_name = f"images/{data['_id']}.jpg"
                zf.writestr(image_name, image_bytes)

    memory_file.seek(0)
    return send_file(memory_file, download_name='data_export.zip', as_attachment=True)

if __name__ == '__main__':
    app.run(debug=True)
