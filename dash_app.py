import dash
import dash_core_components as dcc
import dash_html_components as html
from dash.dependencies import Input, Output, State
import numpy as np
from keras.models import load_model
from keras.preprocessing.text import Tokenizer
from keras.preprocessing.sequence import pad_sequences
import pickle

app = dash.Dash(__name__)
server = app.server

def load_models():
	# Load my pre-trained Keras model
	global model, tokenizer
	model = load_model('yelp_nn_model.h5')
	with open('keras_tokenizer.pickle', 'rb') as f:
		tokenizer = pickle.load(f)
	return model, tokenizer

model, tokenizer = load_models()

def prepare_text(text):
	'''Need to Tokenize text and pad sequences'''
	words = tokenizer.texts_to_sequences(text)
	words_padded = pad_sequences(words, maxlen = 200)

	return words_padded


app.layout = html.Div(children=[
	html.H1("Restaurant Review Predictions"),	
	html.H3("Enter the text of a restaurant review and I'll predict what I think it's star rating is!"),
	dcc.Markdown('''For more on the model generating the predictions, visit
	 [here](https://www.kaggle.com/athoul01/predicting-yelp-ratings-from-review-text). To learn about the data set
	 check out my blog [post](https://www.ahoulette.com/2018/04/11/reviewing-yelp/)'''),
	dcc.Markdown('''Powered by data from the [Yelp](https://www.yelp.com/dataset/challenge) academic data set'''),
	dcc.Textarea(id = 'review', value = '', style={'width': '100%', 'rows': '5'}),
	html.Button(id = 'submit-button', n_clicks = 0, children = 'Submit'),
	html.Div(id='output-state')
])

@app.callback(Output('output-state', 'children'),
	[Input('submit-button', 'n_clicks')],	
	[State('review', 'value')])
def predict_text(submit, review):
	if review is not None and review is not '':
		try:
			clean_text = prepare_text([review])
			preds = model.predict(clean_text)
			#return 'This review sounds like a {} star review.'.format(np.argmax(preds, axis = 1)[0] + 1)
			return 'This review sounds like a {0} star review. I am {1:.2f}% confident.'.format(np.argmax(preds, axis = 1)[0] + 1,
				np.max(preds, axis = 1)[0]*100)
		except ValueError as e:
			print(e)
			return "Unable to predict rating."


if __name__ == '__main__':
	app.run_server(debug=False, threaded = False)
