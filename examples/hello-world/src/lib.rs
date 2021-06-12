use solana_program::account_info::AccountInfo;
use solana_program::entrypoint;
use solana_program::program_error::ProgramError;
use solana_program::pubkey::Pubkey;
use solana_program::msg;

entrypoint!(hello_world);

pub fn hello_world(program_id: &Pubkey, accounts: &[AccountInfo], ix_data: &[u8]) -> Result<(), ProgramError> {
   msg!("Data: {:?}", ix_data);
   Ok(()) 
}
