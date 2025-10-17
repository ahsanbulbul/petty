# Plan for Vision Model
*Using Supabase for auth + main DB, Vision API for AI processing*

---

1. ✅ Idea exploration and necessary models / architecture
2. ✅ Exploration of models
3. ✅ Rough architecture + check model accuracy
4. ✅ Decide the best model to use (YOLOv8-Seg + DINOv2)
5. ✅ Improve and fix Image detection
6. ✅ implement complete detection from metadata

7. **Convert service to RestAPI**
    
    **POST /api/v1/lost**
    - Receive: JSON data (images, pet_type, location, timestamp, description, etc.)
    - Do:
        i. Generate embeddings from images (YOLOv8 + DINOv2)
        ii. Save embeddings + metadata to local `lost_pets` DB
        iii. Check for matches in local `found_pets` DB (above threshold)
        iv. Return best match with confidence score
    - Return: match_found (bool), best_match (if any), confidence, match_details
    
    **POST /api/v1/found**
    - Receive: JSON data (images, pet_type, location, timestamp, description, etc.)
    - Do:
        i. Generate embeddings from images (YOLOv8 + DINOv2)
        ii. Save embeddings + metadata to local `found_pets` DB
        iii. Check for matches in local `lost_pets` DB (above threshold)
        iv. Return best match with confidence score
    - Return: match_found (bool), best_match (if any), confidence, match_details
    
    **DELETE /api/v1/solvedlost/{id}**
    - Receive: post_id
    - Do: Delete entry from local `lost_pets` DB
    - Return: success (optimizes future matching time)
    
    **DELETE /api/v1/solvedfound/{id}**
    - Receive: post_id
    - Do: Delete entry from local `found_pets` DB
    - Return: success (optimizes future matching time)
    
    **GET /api/v1/health**
    - Return: models_loaded, gpu_available, db_status

    **Note:** Vision API maintains its own local database (SQLite/PostgreSQL) separate from Supabase. Supabase only handles auth and user-facing data.

8. **Dockerize the entire system** (Optional)
    - Create Dockerfile with GPU support
    - Include Redis for caching
    - Set up docker-compose for local dev
    - Deploy to GPU-enabled hosting (Render/Railway/AWS)