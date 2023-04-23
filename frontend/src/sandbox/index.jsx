import {useState, useReducer} from 'react';
import {Tabs, Stack, Button, Tab,Input, Typography, Box, Container} from '@mui/material';

const SidePanel = () => {

  const [nr, setNr] = useState(1)

  return (
  <Box>
    <Stack direction="column">
      <Button> React! </Button>
      <Input
        value={nr}
        onChange={event => {setNr(event.target.value)}}
      />
      <Button> React! </Button>
    </Stack>
  </Box>
)
}

const GenericControls = () => {}
const InertMols = () => {}
const ActiveMols = () => {}
const Reactions = () => {}

export const Sandbox = () => {
  return (
    <div>
      <SidePanel/>
      <Stack direction="row">
        <GenericControls/>
        <InertMols/>
        <ActiveMols/>
        <Reactions/>
      </Stack>
    </div>
  )
}
