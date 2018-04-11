library(jsonlite)
library(tibble)
library(dplyr)
library(stringr)
library(tidyr)
# can't just use fromJSON because this is an NDJSON file
business <- stream_in(file('dataset/business.json'))
business_flat <- flatten(business)
business_tbl <- as_data_frame(business_flat)

# Stream in reviews
reviews <- stream_in(file('dataset/review.json'))
reviews_flat <- flatten(reviews)
reviews_tbl <- as_data_frame(reviews_flat)

# #User file
# users <- stream_in(file('dataset/user.json'))
# users_flat <- flatten(users)
# users_tbl <- as_data_frame(users_flat)


# # Tip file
# tips <- stream_in(file('dataset/tip.json'))
# tips_flat <- flatten(tips)
# tips_tbl <- as_data_frame(tips_flat)

# #checkins file
# checkin <- stream_in(file('dataset/checkin.json'))
# checkin_flat <- flatten(checkin)
# checkin_tbl <- as_data_frame(checkin_flat)


# I want to create a subset of the reviews, businesses and checkin's for some visualization
# I'm only really interested in the restaurants for the time being, so I'm getting rid of
# everything else
############################################################################################
# TO KEEP:
  # BUSINESS.JSON
    # Business ID
    # Business Name
    # Neighborhood
    # City
    # State
    # Postal Code
    # Rating
    # # of reviews
    # close/open
    # Categories - This is where the restaurant tag lies
restaurants <- business_tbl%>%
  select(-starts_with('hours'), -starts_with('attribute'))%>%
  filter(str_detect(categories, 'Restaurant'))%>%
  select(-address, -latitude, -longitude)

# I'm only going to want english language reviews for modeling. Will go ahead and 
# break down categories here too.
us_restaurants <- restaurants%>%
  filter(state %in% state.abb)%>%
  unnest(categories)%>%
  filter(categories != "Restaurants")

saveRDS(us_restaurants, file = 'us_restaurants.rds')

non_us_restaurants <- restaurants%>%
  filter(!(state %in% state.abb))

saveRDS(non_us_restaurants, file = 'non_us_restaurants.rds')
############################################################################################
  # REVIEW.JSON
    # Business ID
    # star rating
    # Text
    # Date
    # useful
    # funny
    # cool
    # Date
rev <- reviews_tbl%>%
  select(-user_id)%>%
  filter(business_id %in% us_restaurants$business_id)

rev_text_and_rating <- rev %>%
  select(review_id, business_id, text, stars, date)

sample_revs_small <- rev_text_and_rating%>%
  sample_n(size = 50000)
sample_revs_large <- rev_text_and_rating%>%
  sample_n(size = 250000)


saveRDS(sample_revs_small, file = 'sample_reviews_small.rds')
saveRDS(sample_revs_large, file = 'sample_reviews_large.rds')

saveRDS(rev_text_and_rating, file = 'rev_text_and_rating.rds')
write_feather(rev_text_and_rating, 'rev_text_and_rating.feather')
