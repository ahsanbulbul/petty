"""
Test script for Pet Matching API
Run this after starting the API server to verify it works
"""

import requests
import json
from datetime import datetime
from pathlib import Path
import base64

# API base URL
BASE_URL = "http://localhost:8000"

# API Key for authentication
API_KEY = "RXN0ZXIgRWdn"

# Headers with API key
HEADERS = {
    "X-API-Key": API_KEY
}

def image_to_base64(image_path: str) -> str:
    """Convert image file to base64 string"""
    with open(image_path, 'rb') as img_file:
        return base64.b64encode(img_file.read()).decode('utf-8')

def print_section(title):
    """Print a section header"""
    print("\n" + "="*80)
    print(f"  {title}")
    print("="*80 + "\n")

def test_health_check():
    """Test the health check endpoint"""
    print_section("Testing Health Check Endpoint")
    
    response = requests.get(f"{BASE_URL}/api/v1/health")
    
    print(f"Status Code: {response.status_code}")
    print(f"Response:\n{json.dumps(response.json(), indent=2)}")
    
    return response.status_code == 200


def test_invalid_api_key():
    """Test that invalid API key is rejected"""
    print_section("Testing Invalid API Key Rejection")
    
    invalid_headers = {"X-API-Key": "INVALID_KEY"}
    
    # Try to submit with invalid key
    lost_pet = {
        "id": "TEST_INVALID",
        "pet_type": "cat",
        "latitude": 23.8103,
        "longitude": 90.4125,
        "timestamp": datetime.now().isoformat(),
        "images": ["dummybase64"],
        "gender": "male"
    }
    
    response = requests.post(
        f"{BASE_URL}/api/v1/lost",
        json=lost_pet,
        headers=invalid_headers
    )
    
    print(f"Status Code: {response.status_code}")
    
    if response.status_code == 401:
        print(f"✓ Correctly rejected invalid API key")
        print(f"Response: {response.json()}")
        return True
    else:
        print(f"✗ Should have rejected invalid API key!")
        return False


def test_missing_api_key():
    """Test that missing API key is rejected"""
    print_section("Testing Missing API Key Rejection")
    
    # Try to submit without API key header
    lost_pet = {
        "id": "TEST_NO_KEY",
        "pet_type": "cat",
        "latitude": 23.8103,
        "longitude": 90.4125,
        "timestamp": datetime.now().isoformat(),
        "images": ["dummybase64"],
        "gender": "male"
    }
    
    response = requests.post(
        f"{BASE_URL}/api/v1/lost",
        json=lost_pet
        # No headers = no API key
    )
    
    print(f"Status Code: {response.status_code}")
    
    if response.status_code == 422:  # FastAPI validation error for missing header
        print(f"✓ Correctly rejected missing API key")
        print(f"Response: {response.json()}")
        return True
    else:
        print(f"✗ Should have rejected missing API key!")
        return False

def test_submit_lost_pet():
    """Test submitting a lost pet"""
    print_section("Testing Submit Lost Pet Endpoint")
    
    # Image paths (relative to visionModel directory)
    image_paths = [
        "../images/a.jpg",
        "../images/b.jpg"
    ]
    
    # Convert images to base64
    images_b64 = []
    for img_path in image_paths:
        if Path(img_path).exists():
            images_b64.append(image_to_base64(img_path))
        else:
            print(f"⚠ Warning: Image not found: {img_path}")
    
    if not images_b64:
        print("❌ No valid images found. Skipping test.")
        return False
    
    # Example lost pet data
    lost_pet = {
        "id": "TEST_LOST_001",
        "pet_type": "cat",
        "latitude": 23.8103,
        "longitude": 90.4125,
        "timestamp": datetime.now().isoformat(),
        "images": images_b64,
        "gender": "male",
        "description": "Orange tabby with white paws"
    }
    
    print(f"Submitting lost pet with {len(images_b64)} image(s)...\n")
    
    response = requests.post(
        f"{BASE_URL}/api/v1/lost",
        json=lost_pet,
        headers=HEADERS
    )
    
    print(f"Status Code: {response.status_code}")
    
    if response.status_code == 200:
        result = response.json()
        print(f"Success! Match Found: {result['match_found']}")
        print(f"Response:\n{json.dumps(result, indent=2)}")
        return True
    else:
        print(f"Error: {response.text}")
        return False

def test_submit_found_pet():
    """Test submitting a found pet"""
    print_section("Testing Submit Found Pet Endpoint")
    
    # Image paths (relative to visionModel directory)
    image_paths = ["../images/p.jpg"]
    
    # Convert images to base64
    images_b64 = []
    for img_path in image_paths:
        if Path(img_path).exists():
            images_b64.append(image_to_base64(img_path))
        else:
            print(f"⚠ Warning: Image not found: {img_path}")
    
    if not images_b64:
        print("❌ No valid images found. Skipping test.")
        return False
    
    # Example found pet data
    found_pet = {
        "id": "TEST_FOUND_001",
        "pet_type": "cat",
        "latitude": 23.8150,
        "longitude": 90.4180,
        "timestamp": datetime.now().isoformat(),
        "images": images_b64,
        "gender": "male",
        "description": "Orange cat found near park"
    }
    
    print(f"Submitting found pet with {len(images_b64)} image(s)...\n")
    
    response = requests.post(
        f"{BASE_URL}/api/v1/found",
        json=found_pet,
        headers=HEADERS
    )
    
    print(f"Status Code: {response.status_code}")
    
    if response.status_code == 200:
        result = response.json()
        print(f"Success! Match Found: {result['match_found']}")
        print(f"Response:\n{json.dumps(result, indent=2)}")
        return True
    else:
        print(f"Error: {response.text}")
        return False

def test_delete_lost_pet(pet_id="TEST_LOST_001"):
    """Test deleting a lost pet"""
    print_section("Testing Delete Lost Pet Endpoint")
    
    response = requests.delete(
        f"{BASE_URL}/api/v1/solvedlost/{pet_id}",
        headers=HEADERS
    )
    
    print(f"Status Code: {response.status_code}")
    print(f"Response:\n{json.dumps(response.json(), indent=2)}")
    
    return response.status_code == 200

def test_delete_found_pet(pet_id="TEST_FOUND_001"):
    """Test deleting a found pet"""
    print_section("Testing Delete Found Pet Endpoint")
    
    response = requests.delete(
        f"{BASE_URL}/api/v1/solvedfound/{pet_id}",
        headers=HEADERS
    )
    
    print(f"Status Code: {response.status_code}")
    print(f"Response:\n{json.dumps(response.json(), indent=2)}")
    
    return response.status_code == 200

def check_image_files():
    """Check if required test image files exist"""
    print_section("Checking Test Image Files")
    
    required_images = [
        "../images/a.jpg",
        "../images/b.jpg",
        "../images/p.jpg"
    ]
    
    all_exist = True
    for img_path in required_images:
        exists = Path(img_path).exists()
        status = "✓" if exists else "✗"
        print(f"  {status} {img_path}")
        if not exists:
            all_exist = False
    
    if not all_exist:
        print("\n⚠ Warning: Some test images are missing!")
        print("Update the image paths in this script to match your actual image files.")
    
    return all_exist

def run_all_tests():
    """Run all API tests"""
    print("\n" + "="*80)
    print("  PET MATCHING API - TEST SUITE")
    print("="*80)
    
    # Check if API is running
    try:
        response = requests.get(f"{BASE_URL}/api/v1/health", timeout=5)
    except requests.exceptions.ConnectionError:
        print("\n❌ ERROR: Cannot connect to API server")
        print(f"Make sure the server is running at {BASE_URL}")
        print("\nStart the server with: python api.py")
        return
    
    # Check image files
    if not check_image_files():
        print("\nContinuing with tests (may fail if images don't exist)...")
    
    # Run tests
    tests = [
        ("Health Check", test_health_check),
        ("Invalid API Key", test_invalid_api_key),
        ("Missing API Key", test_missing_api_key),
        ("Submit Lost Pet", test_submit_lost_pet),
        ("Submit Found Pet", test_submit_found_pet),
        ("Delete Lost Pet", lambda: test_delete_lost_pet("TEST_LOST_001")),
        ("Delete Found Pet", lambda: test_delete_found_pet("TEST_FOUND_001")),
    ]
    
    results = []
    for test_name, test_func in tests:
        try:
            success = test_func()
            results.append((test_name, success))
        except Exception as e:
            print(f"\n❌ Test failed with exception: {e}")
            results.append((test_name, False))
    
    # Summary
    print_section("TEST SUMMARY")
    
    passed = sum(1 for _, success in results if success)
    total = len(results)
    
    for test_name, success in results:
        status = "✓ PASS" if success else "✗ FAIL"
        print(f"  {status}: {test_name}")
    
    print(f"\nTotal: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 All tests passed!")
    else:
        print("\n⚠ Some tests failed. Check the output above for details.")

if __name__ == "__main__":
    run_all_tests()
