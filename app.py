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
        
        # Extract values
        ph = float(data['ph'])
        tds = float(data['tds'])
        
        # Input validation
        if ph < 0 or ph > 14:
            return jsonify({'error': 'pH must be between 0 and 14'}), 400
        
        if tds < 0:
            return jsonify({'error': 'TDS cannot be negative'}), 400
        
        # If model failed to load, use simple logic
        if model is None or scaler is None:
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
        user_scaled = scaler.transform(user_input)
        
        # Get prediction probabilities
        proba = model.predict_proba(user_scaled)
        
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