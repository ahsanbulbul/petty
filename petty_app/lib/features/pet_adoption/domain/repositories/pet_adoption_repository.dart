// lib/features/pet_adoption/domain/entities/pet_adoption_repository.dart
import '../entities/pet_adoption.dart';

abstract class PetAdoptionRepository {
  Future<PetAdoption> addPet(PetAdoption pet, {dynamic imageFile});
  Future<List<PetAdoption>> getAllPets();
  Stream<List<PetAdoption>> watchAllPets();

  Future<AdoptionRequest> requestAdoption(AdoptionRequest req);
  Stream<List<AdoptionRequest>> watchAdoptionRequests();
  Future<List<AdoptionRequest>> getRequestsForPet(String petId);
  Future<List<AdoptionRequest>> getMyRequests(String userId);
  Future<void> updateRequestStatus(String requestId, String status);
  Future<void> markPetAdopted(String petId);
}
