/*	PriorityQueue
 *
 *	By Eric Parker
 *	A priority queue implemented with a heap.
 *	The Compare type is used to order the elements.
 *	b in "a comp b" will be earlier/higher in the heap.
 */

#ifndef _PriorityQueue_h
#define _PriorityQueue_h

#include <functional>

#include "Array.h"

template <class T> class NoMove {
public:
  void operator()(const T& p, int32 iNewIndex) const {}
};

template <class T, class Compare = std::less<T>, class Moved = NoMove<T> >
class PriorityQueue {
public:
	const T& top() { return vec_[0]; }
	void push(const T& value);
	void pop() { remove(0); }
	void higher(int32 i) { upHeap(vec_.begin(), i, 0, vec_[i]); }	// Value became higher
	void lower(int32 i) { downHeap(vec_.begin(), i, vec_.size(), vec_[i]); }	// Value became lower
	void remove(int32 i);
	int32 size() const { return vec_.size(); }
	bool empty() const { return vec_.empty(); }
	const T& operator[](int32 i) const { return vec_[i]; }
	void clear();

private:
	Compare comp_;
	Moved moved_;
	Array<T> vec_;

	void upHeap(T* first, int32 holeIndex, int32 topIndex, T value);
	void upHeapAlways(T* first, int32 holeIndex, int32 topIndex, T value);
	void downHeap(T* first, int32 holeIndex, uint32 len, T value);
};


template <class T, class Compare, class Moved> 
inline void PriorityQueue<T, Compare, Moved>::push(const T& value) 
{
	vec_.push_back(value);
	typename Array<T>::iterator itLast = vec_.end() - 1;
	upHeap(&*vec_.begin(), itLast - vec_.begin(), 0, *itLast);
}

template <class T, class Compare, class Moved> 
inline void PriorityQueue<T, Compare, Moved>::remove(int32 i)
{
	upHeapAlways(&*vec_.begin(), i, 0, vec_[i]);
	typename Array<T>::iterator itLast = vec_.end() - 1;
	moved_(vec_[0], -1);				// -1 Indicates not in heap anymore
	vec_[0]	= *itLast;
	downHeap(&*vec_.begin(), 0, itLast - vec_.begin(), vec_[0] );
	vec_.erase(itLast);
}

//	upHeap, and downHeap based on algorithms from the STL
template <class T, class Compare, class Moved> inline void
PriorityQueue<T, Compare, Moved>::upHeap(T* first, int32 holeIndex, int32 topIndex, T value)
{
	int32 parent = (holeIndex - 1) / 2;
	while (holeIndex > topIndex && comp_(*(first + parent), value)) 
	{
		moved_(*(first + parent), holeIndex);
		*(first + holeIndex) = *(first + parent);
		holeIndex = parent;
		parent = (holeIndex - 1) / 2;
	}
	moved_(value, holeIndex);
	*(first + holeIndex) = value;
}

//	This is the same as upHeap() except comp_() isn't called (meaning that value is always > its parent)
template <class T, class Compare, class Moved> inline void
PriorityQueue<T, Compare, Moved>::upHeapAlways(T* first, int32 holeIndex, int32 topIndex, T value) 
{
	int32 parent = (holeIndex - 1) / 2;
	while (holeIndex > topIndex ) 
	{
		moved_(*(first + parent), holeIndex);
		*(first + holeIndex) = *(first + parent);
		holeIndex = parent;
		parent = (holeIndex - 1) / 2;
	}
	moved_(value, holeIndex);
	*(first + holeIndex) = value;
}

template <class T, class Compare, class Moved> 
inline void PriorityQueue<T, Compare, Moved>::downHeap(T* first, int32 holeIndex, uint32 len, T value) 
{
	int32 topIndex = holeIndex;
	uint32 secondChild = 2 * holeIndex + 2;
	while (secondChild < len) 
	{
		if( comp_(*(first + secondChild), *(first + (secondChild - 1))) )
			secondChild--;
		moved_(*(first + secondChild), holeIndex);
		*(first + holeIndex) = *(first + secondChild);
		holeIndex = secondChild;
		secondChild = 2 * secondChild + 2;
	}
	if (secondChild == len) 
	{
		moved_(*(first + (secondChild - 1)), holeIndex);
		*(first + holeIndex) = *(first + (secondChild - 1));
		holeIndex = secondChild - 1;
	}
	upHeap(first, holeIndex, topIndex, value);
}

template <class T, class Compare, class Moved> 
inline void PriorityQueue<T, Compare, Moved>::clear()
{
	vec_.clear();
}

#endif
