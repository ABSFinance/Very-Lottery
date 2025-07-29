import React from 'react'
import {
    Modal,
    ModalOverlay,
    ModalContent,
    ModalHeader,
    ModalFooter,
    ModalBody,
    ModalCloseButton,
    Button,
    Text,
    List,
    ListItem,
    Box
  } from '@chakra-ui/react'
import Spinner from './Spinner'
  
const LotteryDetailModal = ({isOpen, onClose, lId, data, isDetailLoading}) => {

  return (
    <>
      <Modal isOpen={isOpen} onClose={onClose}>
        <ModalOverlay />
        <ModalContent>
          <ModalHeader>Eth-Lottery ID: {lId.toString()}</ModalHeader>
          <ModalCloseButton />
          <ModalBody>
            {(isDetailLoading) ? <Spinner/> :
              <>
                {(typeof data[lId] !== 'undefined') ? 
                    <List spacing={2}>
                    <ListItem>
                      <Text as={'span'} fontWeight={'bold'}>
                        Ticket Price:
                      </Text>{' '}
                      <Text>
                        {data[lId]['ticketPrice']} VERY
                      </Text>
                    </ListItem>
                    <ListItem>
                      <Text as={'span'} fontWeight={'bold'}>
                        Active Players:
                      </Text>{' '}
                      {data[lId]['players']}
                    </ListItem>
                    <ListItem>
                      <Text as={'span'} fontWeight={'bold'}>
                        Current Price Pool:
                      </Text>{' '}
                      <Box>
                        <Text fontWeight="bold">Price Pool:</Text>
                        <Text>
                          {data[lId]['pricePool']} VERY
                        </Text>
                      </Box>
                    </ListItem>
                  </List>
                  :
                  ''
                }
              </>
            }
          </ModalBody>

          <ModalFooter>
            <Button size={'sm'} colorScheme='blue' mr={3} onClick={onClose}>
              Close
            </Button>
          </ModalFooter>
        </ModalContent>
      </Modal>
    </>
  )
}

export default LotteryDetailModal