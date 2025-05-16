from flask import Flask, request, jsonify
import pickle
import numpy as np
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Load the saved model and scaler
try:
    model = pickle.load(open('water_potability_model.pkl', 'rb'))
    scaler = pickle.load(open('water_potability_scaler.pkl', 'rb'))
    print("Model and scaler loaded successfully!")
except Exception as e:
    print(f"Error loading model or scaler: {e}")
    # Provide default values in case loading fails
    model = None
    scaler = None

@app.route('/predict', methods=['POST'])
def predict():
    try:
        # Get the data from the POST request
        data = request.get_json(force=True)
        
        # Extract required values
        ph = float(data['ph'])
        solids = float(data['solids'])
        
        # Extract optional values with defaults
        hardness = float(data.get('hardness', 0))
        chloramines = float(data.get('chloramines', 0))
        sulfate = float(data.get('sulfate', 0))
        conductivity = float(data.get('conductivity', 0))
        organic_carbon = float(data.get('organic_carbon', 0))
        trihalomethanes = float(data.get('trihalomethanes', 0))
        turbidity = float(data.get('turbidity', 0))
        
        # Input validation
        if ph < 0 or ph > 14:
            return jsonify({'error': 'pH must be between 0 and 14'}), 400
        
        if solids < 0:
            return jsonify({'error': 'Solids cannot be negative'}), 400
        
        # If model failed to load, use simple logic
        if model is None or scaler is None:
            # Simplified logic when model not available
            is_good_ph = 6.5 <= ph <= 8.5
            is_good_solids = solids < 500
            
            if is_good_ph and is_good_solids:
                potable_prob = 85.0
            elif is_good_ph or is_good_solids:
                potable_prob = 60.0
            else:
                potable_prob = 30.0
                
            return jsonify({
                'potable_probability': float(potable_prob),
                'not_potable_probability': float(100 - potable_prob),
                'is_potable': bool(potable_prob > 50)
            })
        
        # Prepare input for the model
        user_input = np.array([[
            ph, solids, hardness, chloramines, sulfate,
            conductivity, organic_carbon, trihalomethanes, turbidity
        ]])
        
        # Scale the input
        user_scaled = scaler.transform(user_input)
        
        # Make prediction
        prediction = model.predict(user_scaled)[0]
        probability = model.predict_proba(user_scaled)[0][1] * 100
        
        return jsonify({
            'potable_probability': float(probability),
            'not_potable_probability': float(100 - probability),
            'is_potable': bool(prediction == 1)
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)