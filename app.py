from flask import Flask, request, jsonify
import pickle
import numpy as np
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Load the saved models and scalers
try:
    model_2features = pickle.load(open('water_potability_model_2features.pkl', 'rb'))
    scaler_2features = pickle.load(open('water_potability_scaler_2features.pkl', 'rb'))
    model_9features = pickle.load(open('water_potability_model_9features.pkl', 'rb'))
    scaler_9features = pickle.load(open('water_potability_scaler_9features.pkl', 'rb'))
    print("Models and scalers loaded successfully!")
except Exception as e:
    print(f"Error loading models or scalers: {e}")
    # Provide default values in case loading fails
    model_2features = None
    scaler_2features = None
    model_9features = None
    scaler_9features = None

@app.route('/predict', methods=['POST'])
def predict():
    try:
        # Get the data from the POST request
        data = request.get_json(force=True)
        
        # Extract values
        ph = float(data['ph'])
        tds = float(data['tds'])
        
        # Input validation
        if ph < 0 or ph > 14:
            return jsonify({'error': 'pH must be between 0 and 14'}), 400
        
        if tds < 0:
            return jsonify({'error': 'TDS cannot be negative'}), 400
        
        # If model failed to load, use simple logic
        if model_2features is None or scaler_2features is None:
            # Simplified logic when model not available
            is_good_ph = 6.5 <= ph <= 8.5
            is_good_tds = tds < 500
            
            if is_good_ph and is_good_tds:
                potable_prob = 85.0
            elif is_good_ph or is_good_tds:
                potable_prob = 60.0
            else:
                potable_prob = 30.0
                
            return jsonify({
                'potable_probability': float(potable_prob),
                'not_potable_probability': float(100 - potable_prob),
                'is_potable': bool(potable_prob > 50)
            })
        
        # Prepare input for the model
        user_input = np.array([[ph, tds]])
        
        # Scale the input
        user_scaled = scaler_2features.transform(user_input)
        
        # Get prediction probabilities
        proba = model_2features.predict_proba(user_scaled)
        
        # Prepare response
        response = {
            'potable_probability': float(proba[0][1] * 100),
            'not_potable_probability': float(proba[0][0] * 100),
            'is_potable': bool(proba[0][1] > 0.5)
        }
        
        return jsonify(response)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/predict_9features', methods=['POST'])
def predict_9features():
    try:
        # Get the data from the POST request
        data = request.get_json(force=True)
        
        # Extract values
        ph = float(data['ph'])
        tds = float(data['tds'])
        hardness = float(data['hardness'])
        solids = float(data['solids'])
        chloramines = float(data['chloramines'])
        sulfate = float(data['sulfate'])
        conductivity = float(data['conductivity'])
        organic_carbon = float(data['organic_carbon'])
        trihalomethanes = float(data['trihalomethanes'])
        
        # Input validation
        if ph < 0 or ph > 14:
            return jsonify({'error': 'pH must be between 0 and 14'}), 400
        
        if any(value < 0 for value in [tds, hardness, solids, chloramines, sulfate, conductivity, organic_carbon, trihalomethanes]):
            return jsonify({'error': 'All parameters must be non-negative'}), 400
        
        # If model failed to load, use simple logic
        if model_9features is None or scaler_9features is None:
            # Simplified logic when model not available
            is_good_ph = 6.5 <= ph <= 8.5
            is_good_tds = tds < 500
            is_good_hardness = 150 <= hardness <= 300
            is_good_solids = solids < 500
            is_good_chloramines = 2 <= chloramines <= 4
            is_good_sulfate = sulfate < 250
            is_good_conductivity = conductivity < 500
            is_good_organic_carbon = organic_carbon < 2.5
            is_good_trihalomethanes = trihalomethanes < 80
            
            # Count good parameters
            good_params = sum([
                is_good_ph, is_good_tds, is_good_hardness, is_good_solids,
                is_good_chloramines, is_good_sulfate, is_good_conductivity,
                is_good_organic_carbon, is_good_trihalomethanes
            ])
            
            potable_prob = (good_params / 9) * 100
            
            # Adjust probability based on critical parameters
            if not is_good_ph or not is_good_tds:
                potable_prob *= 0.7
            
            return jsonify({
                'potable_probability': float(potable_prob),
                'not_potable_probability': float(100 - potable_prob),
                'is_potable': bool(potable_prob > 50)
            })
        
        # Prepare input for the model
        user_input = np.array([[
            ph, hardness, solids, chloramines, sulfate, conductivity,
            organic_carbon, trihalomethanes, tds
        ]])
        
        # Scale the input
        user_scaled = scaler_9features.transform(user_input)
        
        # Get prediction probabilities
        proba = model_9features.predict_proba(user_scaled)
        
        # Prepare response
        response = {
            'potable_probability': float(proba[0][1] * 100),
            'not_potable_probability': float(proba[0][0] * 100),
            'is_potable': bool(proba[0][1] > 0.5)
        }
        
        return jsonify(response)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)