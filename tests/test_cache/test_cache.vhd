library ieee;
use ieee.std_logic_1164.all;

entity test_cache is
end test_cache;

architecture behavior of test_cache is
  component cache_d is
    port (
      clk                     : in std_logic;         -- clock
      boot                    : in std_logic;         -- boot
      r_w                     : in std_logic;         -- read or write
      cache_mem               : in std_logic;         -- access cache or memory
      b_w                     : in std_logic;         -- byte access or word access
      add_physical            : in std_logic_vector(15 downto 0);
      
      memory_r_w              : out std_logic;
      memory_address          : out std_logic_vector(12 downto 0);
      memory_in               : in std_logic_vector(63 downto 0);
      memory_out              : out std_logic_vector(63 downto 0);
                
      data_in                 : in std_logic_vector(15 downto 0);
      data_out                : out std_logic_vector(15 downto 0)

    );
  end component;
  
  signal clock            : std_logic := '0';
  signal reset            : std_logic := '1';
  signal r_w              : std_logic := '0';
  signal cache_mem        : std_logic := '0';
  signal b_w              : std_logic := '0';
  signal add_physical     : std_logic_vector(15 downto 0) := "0000000000000000";
  
  signal memory_r_w       : std_logic := '1';
  signal memory_address   : std_logic_vector(12 downto 0);
  signal memory_in        : std_logic_vector(63 downto 0);
  signal memory_out       : std_logic_vector(63 downto 0);
  
  signal data_in          : std_logic_vector(15 downto 0) := "0000000000000000";
  signal data_out         : std_logic_vector(15 downto 0);
  
  
  
begin
  cache : cache_d
    port map (
      clk                     => clock,
      boot                    => reset,
      r_w                     => r_w,
      cache_mem               => cache_mem,
      b_w                     => b_w,
      add_physical            => add_physical,
      
      memory_r_w              => memory_r_w,
      memory_address          => memory_address,
      memory_in               => memory_in,
      memory_out              => memory_out,
                
      data_in                 => data_in,
      data_out                => data_out
  );
  
  clock <= not clock after 10 ns;
  reset <= '0' after 100 ns;
  
end behavior;