import '../entities/pet_match.dart';
import '../../../lost_pets/domain/entities/pet_ping.dart';

abstract class PetMatchingRepository {
  Future<PetMatch?> submitLostPet(PetPing ping);
  Future<PetMatch?> submitFoundPet(PetPing ping);
  Future<bool> markLostPetAsSolved(String id);
  Future<bool> markFoundPetAsSolved(String id);
  Future<bool> checkApiHealth();
  Future<List<PetMatch>> getCurrentUserMatches();
}